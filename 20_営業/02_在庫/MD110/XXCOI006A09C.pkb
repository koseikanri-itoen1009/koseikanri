CREATE OR REPLACE PACKAGE BODY XXCOI006A09C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A09C(body)
 * Description      : ���ގ���������Ɍ����݌Ɏ󕥕\�i�����j���쐬���܂�
 * MD.050           : �����݌Ɏ󕥕\�쐬<MD050_COI_006_A09>
 * Version          : 1.11
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ----------------------------------------------------------
 *  set_last_daily_sum           �O���T�}�����o��                   (A-7)
 *  finalize                     �I������                             (A-9)
 *  set_reception_sum            �݌v�󕥃f�[�^�o��                   (A-8)
 *  upd_last_transaction_id      �ŏI���ID�X�V                       (A-6)
 *  set_last_daily_data          ����������f�[�^�󕥏o��             (A-5)
 *                               �O���󕥃f�[�^���o                   (A-4)
 *  set_mtl_transaction_data     �����f�[�^�����݌Ɏ󕥁i�����j�o��   (A-3)
 *                               ���ގ���f�[�^���o�i�����j           (A-2)
 *  set_mtl_transaction_data2    �����f�[�^�����݌Ɏ󕥁i�݌v�j�o��   (A-10)
 *                               ���ގ���f�[�^���o�i�݌v�j           (A-11)
 *  init                         ��������                             (A-1)
 *  submain                      ���C�������v���V�[�W��
 *  main                         �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/05    1.0   Sai.u            �V�K�쐬
 *  2009/04/06    1.1   H.Sasaki         [T1_0197]�����݌Ɏ󕥕\�i�݌v�j�̍쐬
 *  2009/05/08    1.2   T.Nakamura       [T1_0839]���_�Ԉړ��I�[�_�[���󕥃f�[�^�쐬�Ώۂɒǉ�
 *  2009/05/14    1.3   H.Sasaki         [T1_0840][T1_0842]�q�֐��ʂ̏W�v�����ύX
 *  2009/05/28    1.4   H.Sasaki         [T1_1234]�݌v�e�[�u���̍쐬���@�C��
 *  2009/06/04    1.5   H.Sasaki         [T1_1324]��������f�[�^�ɂď���VD��ΏۊO�Ƃ���
 *  2009/06/05    1.6   H.Sasaki         [T1_1123]���o�ɂO�̏ꍇ�A�݌v�f�[�^���쐬���Ȃ�
 *  2009/07/30    1.7   N.Abe            [0000638]���ʂ̎擾���ڏC��
 *  2009/08/26    1.8   N.Abe            [0000956]PT�Ή�(�N���p�����[�^�ɂ�鏈������)
 *  2009/08/31    1.9   H.Sasaki         [0001220]�O���f�[�^���f���̌����ݒ���@���C��
 *  2009/09/16    1.10  H.Sasaki         [0001384]PT�Ή��i��������Ȃ��̏ꍇ�A�󕥍쐬���s��Ȃ��j
 *  2009/10/15    1.11  H.Sasaki         [E_�ŏI�ڍs���n_00494]Ver1.10�̏C��
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
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  lock_error_expt           EXCEPTION;
  PRAGMA EXCEPTION_INIT(lock_error_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCOI006A09C'; -- �p�b�P�[�W��
  -- ���t�^
  cv_date               CONSTANT VARCHAR2(8)  :=  'YYYYMMDD';
  cv_month              CONSTANT VARCHAR2(6)  :=  'YYYYMM';
-- == 2009/08/26 V1.8 Added START ===============================================================
  cv_date_time          CONSTANT VARCHAR2(21) :=  'YYYY/MM/DD HH24:MI:SS';
-- == 2009/08/26 V1.8 Added END   ===============================================================
  -- �ۊǏꏊ�敪�i1:�q��  2:�c�Ǝ�  3:�a����  4:���X�j
  cv_subinv_1           CONSTANT VARCHAR2(1)  :=  '1';
  cv_subinv_2           CONSTANT VARCHAR2(1)  :=  '2';
  cv_subinv_3           CONSTANT VARCHAR2(1)  :=  '3';
  cv_subinv_4           CONSTANT VARCHAR2(1)  :=  '4';
  -- ���b�Z�[�W�֘A
  cv_short_name         CONSTANT VARCHAR2(30) :=  'XXCOI';
  cv_msg_xxcoi1_00005   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-00005';
  cv_msg_xxcoi1_00006   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-00006';
  cv_msg_xxcoi1_00011   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-00011';
  cv_msg_xxcoi1_00023   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-00023';
  cv_msg_xxcoi1_10126   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10126';
  cv_msg_xxcoi1_10127   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10127';
  cv_msg_xxcoi1_10128   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10128';
  cv_msg_xxcoi1_10363   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10363';
  cv_msg_xxcoi1_10285   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10285';
  cv_msg_xxcoi1_10293   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10293';
-- == 2009/04/06 V1.1 Added START ===============================================================
  cv_msg_xxcoi1_10378   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10378';
-- == 2009/04/06 V1.1 Added END   ===============================================================
-- == 2009/08/26 V1.8 Added START ===============================================================
  cv_msg_xxcoi1_10365   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10365';         -- �R���J�����g���̓p�����[�^
  cv_msg_xxcoi1_10400   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10400';         -- �Ώۓ����������b�Z�[�W
  cv_msg_xxcoi1_10401   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10401';         -- �p�����[�^�Ώۓ��t���b�Z�[�W
-- == 2009/08/26 V1.8 Added END   ===============================================================
  cv_token_00005_1      CONSTANT VARCHAR2(30) :=  'PRO_TOK';
  cv_token_00006_1      CONSTANT VARCHAR2(30) :=  'ORG_CODE_TOK';
-- == 2009/08/26 V1.8 Added START ===============================================================
  cv_token_10365_1      CONSTANT VARCHAR2(30) :=  'EXEC_FLAG';
  cv_token_10401_1      CONSTANT VARCHAR2(30) :=  'DATE';
-- == 2009/08/26 V1.8 Added END   ===============================================================
  -- �󕥏W�v�L�[�i����^�C�v�j
  cv_trans_type_010     CONSTANT VARCHAR2(3)  :=  '10';        -- ����o��
  cv_trans_type_020     CONSTANT VARCHAR2(3)  :=  '20';        -- ����o�ɐU��
  cv_trans_type_030     CONSTANT VARCHAR2(3)  :=  '30';        -- �ԕi
  cv_trans_type_040     CONSTANT VARCHAR2(3)  :=  '40';        -- �ԕi�U��
  cv_trans_type_050     CONSTANT VARCHAR2(3)  :=  '50';        -- ���o��
  cv_trans_type_060     CONSTANT VARCHAR2(3)  :=  '60';        -- �q��
  cv_trans_type_070     CONSTANT VARCHAR2(3)  :=  '70';        -- ���i�U�ցi�����i�j
  cv_trans_type_080     CONSTANT VARCHAR2(3)  :=  '80';        -- ���i�U�ցi�V���i�j
  cv_trans_type_090     CONSTANT VARCHAR2(3)  :=  '90';        -- ���{�o��
  cv_trans_type_100     CONSTANT VARCHAR2(3)  :=  '100';       -- ���{�o�ɐU��
  cv_trans_type_110     CONSTANT VARCHAR2(3)  :=  '110';       -- �ڋq���{�o��
  cv_trans_type_120     CONSTANT VARCHAR2(3)  :=  '120';       -- �ڋq���{�o�ɐU��
  cv_trans_type_130     CONSTANT VARCHAR2(3)  :=  '130';       -- �ڋq���^���{�o��
  cv_trans_type_140     CONSTANT VARCHAR2(3)  :=  '140';       -- �ڋq���^���{�o�ɐU��
  cv_trans_type_150     CONSTANT VARCHAR2(3)  :=  '150';       -- ����VD��[
  cv_trans_type_160     CONSTANT VARCHAR2(3)  :=  '160';       -- ��݌ɕύX
  cv_trans_type_170     CONSTANT VARCHAR2(3)  :=  '170';       -- �H��ԕi
  cv_trans_type_180     CONSTANT VARCHAR2(3)  :=  '180';       -- �H��ԕi�U��
  cv_trans_type_190     CONSTANT VARCHAR2(3)  :=  '190';       -- �H��q��
  cv_trans_type_200     CONSTANT VARCHAR2(3)  :=  '200';       -- �H��q�֐U��
  cv_trans_type_210     CONSTANT VARCHAR2(3)  :=  '210';       -- �p�p
  cv_trans_type_220     CONSTANT VARCHAR2(3)  :=  '220';       -- �p�p�U��
  cv_trans_type_230     CONSTANT VARCHAR2(3)  :=  '230';       -- �H�����
  cv_trans_type_240     CONSTANT VARCHAR2(3)  :=  '240';       -- �H����ɐU��
  cv_trans_type_250     CONSTANT VARCHAR2(3)  :=  '250';       -- �ڋq�L����`��A���Џ��i
  cv_trans_type_260     CONSTANT VARCHAR2(3)  :=  '260';       -- �ڋq�L����`��A���Џ��i�U��
  cv_trans_type_270     CONSTANT VARCHAR2(3)  :=  '270';       -- �I�����Չv
  cv_trans_type_280     CONSTANT VARCHAR2(3)  :=  '280';       -- �I�����Ց�
  cv_trans_type_290     CONSTANT VARCHAR2(3)  :=  '290';       -- �ړ��I�[�_�[�ړ�
  -- ���̑�
  cn_control_id         CONSTANT NUMBER       :=  50;                           -- �f�[�^�A�g����ID�i�����j
-- == 2009/08/26 V1.8 Added START ===============================================================
  cn_control_id2        CONSTANT NUMBER       :=  80;                           -- �f�[�^�A�g����ID�i�݌v�j
-- == 2009/08/26 V1.8 Added END   ===============================================================
  cv_prf_name_orgcd     CONSTANT VARCHAR2(30) :=  'XXCOI1_ORGANIZATION_CODE';   -- �v���t�@�C�����i�݌ɑg�D�R�[�h�j
  cv_pgsname_a09c       CONSTANT VARCHAR2(30) :=  'XXCOI006A09C';               -- �f�[�^�A�g����e�[�u���p�v���O������
-- == 2009/08/26 V1.8 Added START ===============================================================
  cv_pgsname_b09c       CONSTANT VARCHAR2(12) :=  'XXCOI006B09C';               -- �v���O������(�݌v)
-- == 2009/08/26 V1.8 Added END   ===============================================================
  cv_space              CONSTANT VARCHAR2(1)  :=  ' ';                          -- ���p�X�y�[�X�i���O��s�p�j
  cv_inv_type_5         CONSTANT VARCHAR2(1)  :=  '5';                          -- �ۊǏꏊ�敪�i���̋@�j
  cv_inv_type_8         CONSTANT VARCHAR2(1)  :=  '8';                          -- �ۊǏꏊ�敪�i�����j
-- == 2009/06/04 V1.5 Added START ===============================================================
  cv_subinv_class_7     CONSTANT VARCHAR2(1)  :=  '7';        -- �ۊǏꏊ���ށi7:����VD�j
-- == 2009/06/04 V1.5 Added END   ===============================================================
-- == 2009/08/26 V1.8 Added START ===============================================================
  cv_0                  CONSTANT VARCHAR2(1)  :=  '0';        -- �N���t���O�F�����݌Ɏ󕥕\(����)�쐬
  cv_1                  CONSTANT VARCHAR2(1)  :=  '1';        -- �N���t���O�F�����݌Ɏ󕥕\(�݌v)�쐬
-- == 2009/08/26 V1.8 Added END   ===============================================================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE quantity_type IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  gt_quantity           quantity_type;      -- ����^�C�v�ʐ���
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- ���������ݒ�l
  gd_f_business_date          DATE;               -- �Ɩ��������t
  gv_f_organization_code      VARCHAR2(10);       -- �݌ɑg�D�R�[�h
  gn_f_organization_id        NUMBER;             -- �݌ɑg�DID
  gn_f_last_transaction_id    NUMBER;             -- �����ώ��ID
  gd_f_last_cooperation_date  DATE;               -- �O��ŏI�A�g��
  gn_f_max_transaction_id     NUMBER;             -- �ő���ID
  gd_f_max_practice_date      DATE;               -- �����f�[�^�ő�N�����i�O���j
-- == 2009/08/26 V1.8 Added START ===============================================================
  gv_exec_flag                VARCHAR2(1);        -- �N���t���O(0:�����쐬,1:�݌v�쐬)
-- == 2009/08/26 V1.8 Added END   ===============================================================
-- == 2009/10/15 V1.11 Added START ===============================================================
  gn_material_flag            NUMBER;             -- �Ώۃf�[�^���݃`�F�b�N�t���O
-- == 2009/10/15 V1.11 Added START ===============================================================
--
-- == 2009/08/26 V1.8 Delete START ===============================================================
--  /**********************************************************************************
--   * Procedure Name   : finalize
--   * Description      : �I������(A-9)
--   ***********************************************************************************/
--  PROCEDURE finalize(
--    ov_errbuf         OUT VARCHAR2,                     -- �G���[�E���b�Z�[�W                  --# �Œ� #
--    ov_retcode        OUT VARCHAR2,                     -- ���^�[���E�R�[�h                    --# �Œ� #
--    ov_errmsg         OUT VARCHAR2)                     -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
--  IS
--    -- ===============================
--    -- �Œ胍�[�J���萔
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'finalize'; -- �v���O������
----
----#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
----
--    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
--    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
--    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
----
----###########################  �Œ蕔 END   ####################################
----
--    -- ===============================
--    -- ���[�U�[�錾��
--    -- ===============================
--    -- *** ���[�J���萔 ***
----
--    -- *** ���[�J���ϐ� ***
----
--    -- ===============================
--    -- ���[�J���E�J�[�\��
--    -- ===============================
--    -- <�J�[�\����>
--    -- <�J�[�\����>���R�[�h�^
--  BEGIN
----
----##################  �Œ�X�e�[�^�X�������� START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  �Œ蕔 END   ############################
----
--    -- ***************************************
--    -- ***        ���[�v�����̋L�q         ***
--    -- ***       �������̌Ăяo��          ***
--    -- ***************************************
----
--    --==============================================================
--    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
--    --==============================================================
----
--    -- �����������J�E���g
--    SELECT  COUNT(1)
--    INTO    gn_target_cnt
--    FROM    xxcoi_inv_reception_daily
--    WHERE   request_id    =   cn_request_id;
--    -- ���팏����ݒ�
--    gn_normal_cnt   :=  gn_target_cnt;
----
--  EXCEPTION
----#################################  �Œ��O������ START   ####################################
----
--    -- *** ���������ʗ�O�n���h�� ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** ���ʊ֐���O�n���h�� ***
--    WHEN global_api_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--    -- *** OTHERS��O�n���h�� ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
----
----#####################################  �Œ蕔 END   ##########################################
----
--  END finalize;
-- == 2009/08/26 V1.8 Delete END   ===============================================================
--
-- == 2009/05/28 V1.4 Modified START ===============================================================
-- == 2009/04/06 V1.1 Added START ===============================================================
--  /**********************************************************************************
--   * Procedure Name   : set_reception_sum
--   * Description      : �݌v�󕥃f�[�^�o��(A-7)(A-8)
--   ***********************************************************************************/
--  PROCEDURE set_reception_sum(
--    ov_errbuf                   OUT VARCHAR2,                     -- �G���[�E���b�Z�[�W                  --# �Œ� #
--    ov_retcode                  OUT VARCHAR2,                     -- ���^�[���E�R�[�h                    --# �Œ� #
--    ov_errmsg                   OUT VARCHAR2)                     -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
--  IS
--    -- ===============================
--    -- �Œ胍�[�J���萔
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_reception_sum'; -- �v���O������
----
----#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
----
--    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
--    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
--    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
----
----###########################  �Œ蕔 END   ####################################
----
--    -- ===============================
--    -- ���[�U�[�錾��
--    -- ===============================
--    -- *** ���[�J���萔 ***
----
--    -- *** ���[�J���ϐ� ***
--    ln_dummy      NUMBER;       -- �_�~�[�ϐ�
----
--    -- ===============================
--    -- ���[�J���E�J�[�\��
--    -- ===============================
--    -- �݌v���擾�J�[�\��
--    CURSOR  sum_data_cur
--    IS
--      SELECT  xird.base_code                  base_code                             -- ���_�R�[�h
--             ,xird.organization_id            organization_id                       -- �g�DID
--             ,xird.subinventory_type          subinventory_type                     -- �ۊǏꏊ�敪
--             ,xird.subinventory_code          subinventory_code                     -- �ۊǏꏊ
--             ,SUBSTRB(TO_CHAR(xird.practice_date, cv_date), 1, 6)
--                                              practice_date                         -- �N��
--             ,xird.inventory_item_id          inventory_item_id                     -- �i��ID
--             ,xird.operation_cost             operation_cost                        -- �c�ƌ���
--             ,xird.standard_cost              standard_cost                         -- �W������
--             ,xird.sales_shipped              sales_shipped                         -- ����o��
--             ,xird.sales_shipped_b            sales_shipped_b                       -- ����o�ɐU��
--             ,xird.return_goods               return_goods                          -- �ԕi
--             ,xird.return_goods_b             return_goods_b                        -- �ԕi�U��
--             ,xird.warehouse_ship             warehouse_ship                        -- �q�ɂ֕Ԍ�
--             ,xird.truck_ship                 truck_ship                            -- �c�ƎԂ֏o��
--             ,xird.others_ship                others_ship                           -- ���o�ɁQ���̑��o��
--             ,xird.warehouse_stock            warehouse_stock                       -- �q�ɂ�����
--             ,xird.truck_stock                truck_stock                           -- �c�ƎԂ�����
--             ,xird.others_stock               others_stock                          -- ���o�ɁQ���̑�����
--             ,xird.change_stock               change_stock                          -- �q�֓���
--             ,xird.change_ship                change_ship                           -- �q�֏o��
--             ,xird.goods_transfer_old         goods_transfer_old                    -- ���i�U�ցi�����i�j
--             ,xird.goods_transfer_new         goods_transfer_new                    -- ���i�U�ցi�V���i�j
--             ,xird.sample_quantity            sample_quantity                       -- ���{�o��
--             ,xird.sample_quantity_b          sample_quantity_b                     -- ���{�o�ɐU��
--             ,xird.customer_sample_ship       customer_sample_ship                  -- �ڋq���{�o��
--             ,xird.customer_sample_ship_b     customer_sample_ship_b                -- �ڋq���{�o�ɐU��
--             ,xird.customer_support_ss        customer_support_ss                   -- �ڋq���^���{�o��
--             ,xird.customer_support_ss_b      customer_support_ss_b                 -- �ڋq���^���{�o�ɐU��
--             ,xird.vd_supplement_stock        vd_supplement_stock                   -- ����VD��[����
--             ,xird.vd_supplement_ship         vd_supplement_ship                    -- ����VD��[�o��
--             ,xird.inventory_change_in        inventory_change_in                   -- ��݌ɕύX����
--             ,xird.inventory_change_out       inventory_change_out                  -- ��݌ɕύX�o��
--             ,xird.factory_return             factory_return                        -- �H��ԕi
--             ,xird.factory_return_b           factory_return_b                      -- �H��ԕi�U��
--             ,xird.factory_change             factory_change                        -- �H��q��
--             ,xird.factory_change_b           factory_change_b                      -- �H��q�֐U��
--             ,xird.removed_goods              removed_goods                         -- �p�p
--             ,xird.removed_goods_b            removed_goods_b                       -- �p�p�U��
--             ,xird.factory_stock              factory_stock                         -- �H�����
--             ,xird.factory_stock_b            factory_stock_b                       -- �H����ɐU��
--             ,xird.ccm_sample_ship            ccm_sample_ship                       -- �ڋq�L����`��A���Џ��i
--             ,xird.ccm_sample_ship_b          ccm_sample_ship_b                     -- �ڋq�L����`��A���Џ��i�U��
--             ,xird.wear_decrease              wear_decrease                         -- �I�����Ց�
--             ,xird.wear_increase              wear_increase                         -- �I�����Ռ�
--             ,xird.selfbase_ship              selfbase_ship                         -- �ۊǏꏊ�ړ��Q�����_�o��
--             ,xird.selfbase_stock             selfbase_stock                        -- �ۊǏꏊ�ړ��Q�����_����
--             ,xird.book_inventory_quantity    book_inventory_quantity               -- ����݌ɐ�
--      FROM    xxcoi_inv_reception_daily   xird                                      -- �����݌Ɏ󕥕\�i�����j
--      WHERE   xird.request_id     =   cn_request_id;
--    --
--    -- �݌v���擾���R�[�h�^
--    sum_data_rec  sum_data_cur%ROWTYPE;
--    --
--  BEGIN
----
----##################  �Œ�X�e�[�^�X�������� START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  �Œ蕔 END   ############################
----
--    -- ***************************************
--    -- ***        ���[�v�����̋L�q         ***
--    -- ***       �������̌Ăяo��          ***
--    -- ***************************************
----
--    --==============================================================
--    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
--    --==============================================================
----
--    <<set_sum_data_loop>>
--    FOR sum_data_rec IN sum_data_cur LOOP
--      BEGIN
--        -- ===================================
--        --  1.�݌v�e�[�u�����b�N�擾
--        -- ===================================
--        SELECT  1
--        INTO    ln_dummy
--        FROM    xxcoi_inv_reception_sum   xirs
--        WHERE   xirs.base_code            =   sum_data_rec.base_code
--        AND     xirs.subinventory_code    =   sum_data_rec.subinventory_code
--        AND     xirs.inventory_item_id    =   sum_data_rec.inventory_item_id
--        AND     xirs.practice_date        =   sum_data_rec.practice_date
--        AND     ROWNUM                    =   1
--        FOR UPDATE NOWAIT;
--        --
--        -- ===================================
--        --  2.�݌v�e�[�u���X�V
--        -- ===================================
--        -- ���b�N���擾���ꂽ�ꍇ�A���o�ɐ����X�V����
--        UPDATE  xxcoi_inv_reception_sum
--        SET     sales_shipped             = sales_shipped           + sum_data_rec.sales_shipped            -- 01.����o��
--               ,sales_shipped_b           = sales_shipped_b         + sum_data_rec.sales_shipped_b          -- 02.����o�ɐU��
--               ,return_goods              = return_goods            + sum_data_rec.return_goods             -- 03.�ԕi
--               ,return_goods_b            = return_goods_b          + sum_data_rec.return_goods_b           -- 04.�ԕi�U��
--               ,warehouse_ship            = warehouse_ship          + sum_data_rec.warehouse_ship           -- 05.�q�ɂ֕Ԍ�
--               ,truck_ship                = truck_ship              + sum_data_rec.truck_ship               -- 06.�c�ƎԂ֏o��
--               ,others_ship               = others_ship             + sum_data_rec.others_ship              -- 07.���o�ɁQ���̑��o��
--               ,warehouse_stock           = warehouse_stock         + sum_data_rec.warehouse_stock          -- 08.�q�ɂ�����
--               ,truck_stock               = truck_stock             + sum_data_rec.truck_stock              -- 09.�c�ƎԂ�����
--               ,others_stock              = others_stock            + sum_data_rec.others_stock             -- 10.���o�ɁQ���̑�����
--               ,change_stock              = change_stock            + sum_data_rec.change_stock             -- 11.�q�֓���
--               ,change_ship               = change_ship             + sum_data_rec.change_ship              -- 12.�q�֏o��
--               ,goods_transfer_old        = goods_transfer_old      + sum_data_rec.goods_transfer_old       -- 13.���i�U�ցi�����i�j
--               ,goods_transfer_new        = goods_transfer_new      + sum_data_rec.goods_transfer_new       -- 14.���i�U�ցi�V���i�j
--               ,sample_quantity           = sample_quantity         + sum_data_rec.sample_quantity          -- 15.���{�o��
--               ,sample_quantity_b         = sample_quantity_b       + sum_data_rec.sample_quantity_b        -- 16.���{�o�ɐU��
--               ,customer_sample_ship      = customer_sample_ship    + sum_data_rec.customer_sample_ship     -- 17.�ڋq���{�o��
--               ,customer_sample_ship_b    = customer_sample_ship_b  + sum_data_rec.customer_sample_ship_b   -- 18.�ڋq���{�o�ɐU��
--               ,customer_support_ss       = customer_support_ss     + sum_data_rec.customer_support_ss      -- 19.�ڋq���^���{�o��
--               ,customer_support_ss_b     = customer_support_ss_b   + sum_data_rec.customer_support_ss_b    -- 20.�ڋq���^���{�o�ɐU��
--               ,ccm_sample_ship           = ccm_sample_ship         + sum_data_rec.ccm_sample_ship          -- 21.�ڋq�L����`��A���Џ��i
--               ,ccm_sample_ship_b         = ccm_sample_ship_b       + sum_data_rec.ccm_sample_ship_b        -- 22.�ڋq�L����`��A���Џ��i�U��
--               ,vd_supplement_stock       = vd_supplement_stock     + sum_data_rec.vd_supplement_stock      -- 23.����VD��[����
--               ,vd_supplement_ship        = vd_supplement_ship      + sum_data_rec.vd_supplement_ship       -- 24.����VD��[�o��
--               ,inventory_change_in       = inventory_change_in     + sum_data_rec.inventory_change_in      -- 25.��݌ɕύX����
--               ,inventory_change_out      = inventory_change_out    + sum_data_rec.inventory_change_out     -- 26.��݌ɕύX�o��
--               ,factory_return            = factory_return          + sum_data_rec.factory_return           -- 27.�H��ԕi
--               ,factory_return_b          = factory_return_b        + sum_data_rec.factory_return_b         -- 28.�H��ԕi�U��
--               ,factory_change            = factory_change          + sum_data_rec.factory_change           -- 29.�H��q��
--               ,factory_change_b          = factory_change_b        + sum_data_rec.factory_change_b         -- 30.�H��q�֐U��
--               ,removed_goods             = removed_goods           + sum_data_rec.removed_goods            -- 31.�p�p
--               ,removed_goods_b           = removed_goods_b         + sum_data_rec.removed_goods_b          -- 32.�p�p�U��
--               ,factory_stock             = factory_stock           + sum_data_rec.factory_stock            -- 33.�H�����
--               ,factory_stock_b           = factory_stock_b         + sum_data_rec.factory_stock_b          -- 34.�H����ɐU��
--               ,wear_decrease             = wear_decrease           + sum_data_rec.wear_decrease            -- 35.�I�����Ց�
--               ,wear_increase             = wear_increase           + sum_data_rec.wear_increase            -- 36.�I�����Ռ�
--               ,selfbase_ship             = selfbase_ship           + sum_data_rec.selfbase_ship            -- 37.�ۊǏꏊ�ړ��Q�����_�o��
--               ,selfbase_stock            = selfbase_stock          + sum_data_rec.selfbase_stock           -- 38.�ۊǏꏊ�ړ��Q�����_����
--               ,book_inventory_quantity   = sum_data_rec.book_inventory_quantity                            -- 39.����݌ɐ�
--               ,last_updated_by           = cn_last_updated_by                                              -- 40.�ŏI�X�V��
--               ,last_update_date          = SYSDATE                                                         -- 41.�ŏI�X�V��
--               ,last_update_login         = cn_last_update_login                                            -- 42.�ŏI�X�V���O�C��
--               ,request_id                = cn_request_id                                                   -- 43.�v��ID
--               ,program_application_id    = cn_program_application_id                                       -- 44.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
--               ,program_id                = cn_program_id                                                   -- 45.�R���J�����g�E�v���O����ID
--               ,program_update_date       = SYSDATE                                                         -- 46.�v���O�����X�V��
--        WHERE   base_code                 = sum_data_rec.base_code
--        AND     subinventory_code         = sum_data_rec.subinventory_code
--        AND     inventory_item_id         = sum_data_rec.inventory_item_id
--        AND     practice_date             = sum_data_rec.practice_date;
--        --
--      EXCEPTION
--        WHEN  lock_error_expt THEN
--          -- ���b�N���擾����Ȃ������ꍇ
--          -- �����݌Ɏ󕥁i�݌v�j���b�N�G���[���b�Z�[�W
--          lv_errmsg   := xxccp_common_pkg.get_msg(
--                           iv_application  => cv_short_name
--                          ,iv_name         => cv_msg_xxcoi1_10378
--                         );
--          lv_errbuf   := lv_errmsg;
--          RAISE global_process_expt;
--          --
--        WHEN NO_DATA_FOUND THEN
--          -- ===================================
--          --  3.�݌v�e�[�u���쐬
--          -- ===================================
--          -- �Ώۃf�[�^�����݂��Ȃ��ꍇ�A�݌v����V�K�쐬����
--          INSERT INTO xxcoi_inv_reception_sum(
--            base_code                                   -- 01.���_�R�[�h
--           ,organization_id                             -- 02.�g�DID
--           ,subinventory_code                           -- 03.�ۊǏꏊ
--           ,subinventory_type                           -- 04.�ۊǏꏊ�敪
--           ,practice_date                               -- 05.�N��
--           ,inventory_item_id                           -- 06.�i��ID
--           ,operation_cost                              -- 07.�c�ƌ���
--           ,standard_cost                               -- 08.�W������
--           ,sales_shipped                               -- 09.����o��
--           ,sales_shipped_b                             -- 10.����o�ɐU��
--           ,return_goods                                -- 11.�ԕi
--           ,return_goods_b                              -- 12.�ԕi�U��
--           ,warehouse_ship                              -- 13.�q�ɂ֕Ԍ�
--           ,truck_ship                                  -- 14.�c�ƎԂ֏o��
--           ,others_ship                                 -- 15.���o�ɁQ���̑��o��
--           ,warehouse_stock                             -- 16.�q�ɂ�����
--           ,truck_stock                                 -- 17.�c�ƎԂ�����
--           ,others_stock                                -- 18.���o�ɁQ���̑�����
--           ,change_stock                                -- 19.�q�֓���
--           ,change_ship                                 -- 20.�q�֏o��
--           ,goods_transfer_old                          -- 21.���i�U�ցi�����i�j
--           ,goods_transfer_new                          -- 22.���i�U�ցi�V���i�j
--           ,sample_quantity                             -- 23.���{�o��
--           ,sample_quantity_b                           -- 24.���{�o�ɐU��
--           ,customer_sample_ship                        -- 25.�ڋq���{�o��
--           ,customer_sample_ship_b                      -- 26.�ڋq���{�o�ɐU��
--           ,customer_support_ss                         -- 27.�ڋq���^���{�o��
--           ,customer_support_ss_b                       -- 28.�ڋq���^���{�o�ɐU��
--           ,ccm_sample_ship                             -- 29.�ڋq�L����`��A���Џ��i
--           ,ccm_sample_ship_b                           -- 30.�ڋq�L����`��A���Џ��i�U��
--           ,vd_supplement_stock                         -- 31.����VD��[����
--           ,vd_supplement_ship                          -- 32.����VD��[�o��
--           ,inventory_change_in                         -- 33.��݌ɕύX����
--           ,inventory_change_out                        -- 34.��݌ɕύX�o��
--           ,factory_return                              -- 35.�H��ԕi
--           ,factory_return_b                            -- 36.�H��ԕi�U��
--           ,factory_change                              -- 37.�H��q��
--           ,factory_change_b                            -- 38.�H��q�֐U��
--           ,removed_goods                               -- 39.�p�p
--           ,removed_goods_b                             -- 40.�p�p�U��
--           ,factory_stock                               -- 41.�H�����
--           ,factory_stock_b                             -- 42.�H����ɐU��
--           ,wear_decrease                               -- 43.�I�����Ց�
--           ,wear_increase                               -- 44.�I�����Ռ�
--           ,selfbase_ship                               -- 45.�ۊǏꏊ�ړ��Q�����_�o��
--           ,selfbase_stock                              -- 46.�ۊǏꏊ�ړ��Q�����_����
--           ,book_inventory_quantity                     -- 47.����݌ɐ�
--           ,created_by                                  -- 48.�쐬��
--           ,creation_date                               -- 49.�쐬��
--           ,last_updated_by                             -- 50.�ŏI�X�V��
--           ,last_update_date                            -- 51.�ŏI�X�V��
--           ,last_update_login                           -- 52.�ŏI�X�V���O�C��
--           ,request_id                                  -- 53.�v��ID
--           ,program_application_id                      -- 54.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
--           ,program_id                                  -- 55.�R���J�����g�E�v���O����ID
--           ,program_update_date                         -- 56.�v���O�����X�V��
--          )VALUES(
--            sum_data_rec.base_code                      -- 01
--           ,sum_data_rec.organization_id                -- 02
--           ,sum_data_rec.subinventory_code              -- 03
--           ,sum_data_rec.subinventory_type              -- 04
--           ,sum_data_rec.practice_date                  -- 05
--           ,sum_data_rec.inventory_item_id              -- 06
--           ,sum_data_rec.operation_cost                 -- 07
--           ,sum_data_rec.standard_cost                  -- 08
--           ,sum_data_rec.sales_shipped                  -- 09
--           ,sum_data_rec.sales_shipped_b                -- 10
--           ,sum_data_rec.return_goods                   -- 11
--           ,sum_data_rec.return_goods_b                 -- 12
--           ,sum_data_rec.warehouse_ship                 -- 13
--           ,sum_data_rec.truck_ship                     -- 14
--           ,sum_data_rec.others_ship                    -- 15
--           ,sum_data_rec.warehouse_stock                -- 16
--           ,sum_data_rec.truck_stock                    -- 17
--           ,sum_data_rec.others_stock                   -- 18
--           ,sum_data_rec.change_stock                   -- 19
--           ,sum_data_rec.change_ship                    -- 20
--           ,sum_data_rec.goods_transfer_old             -- 21
--           ,sum_data_rec.goods_transfer_new             -- 22
--           ,sum_data_rec.sample_quantity                -- 23
--           ,sum_data_rec.sample_quantity_b              -- 24
--           ,sum_data_rec.customer_sample_ship           -- 25
--           ,sum_data_rec.customer_sample_ship_b         -- 26
--           ,sum_data_rec.customer_support_ss            -- 27
--           ,sum_data_rec.customer_support_ss_b          -- 28
--           ,sum_data_rec.ccm_sample_ship                -- 29
--           ,sum_data_rec.ccm_sample_ship_b              -- 30
--           ,sum_data_rec.vd_supplement_stock            -- 31
--           ,sum_data_rec.vd_supplement_ship             -- 32
--           ,sum_data_rec.inventory_change_in            -- 33
--           ,sum_data_rec.inventory_change_out           -- 34
--           ,sum_data_rec.factory_return                 -- 35
--           ,sum_data_rec.factory_return_b               -- 36
--           ,sum_data_rec.factory_change                 -- 37
--           ,sum_data_rec.factory_change_b               -- 38
--           ,sum_data_rec.removed_goods                  -- 39
--           ,sum_data_rec.removed_goods_b                -- 40
--           ,sum_data_rec.factory_stock                  -- 41
--           ,sum_data_rec.factory_stock_b                -- 42
--           ,sum_data_rec.wear_decrease                  -- 43
--           ,sum_data_rec.wear_increase                  -- 44
--           ,sum_data_rec.selfbase_ship                  -- 45
--           ,sum_data_rec.selfbase_stock                 -- 46
--           ,sum_data_rec.book_inventory_quantity        -- 47
--           ,cn_created_by                               -- 48
--           ,SYSDATE                                     -- 49
--           ,cn_last_updated_by                          -- 50
--           ,SYSDATE                                     -- 51
--           ,cn_last_update_login                        -- 52
--           ,cn_request_id                               -- 53
--           ,cn_program_application_id                   -- 54
--           ,cn_program_id                               -- 55
--           ,SYSDATE                                     -- 56
--          );
--          --
--      END;
--      --
--    END LOOP set_sum_data_loop;
----
--  EXCEPTION
----#################################  �Œ��O������ START   ####################################
----
--    -- *** ���������ʗ�O�n���h�� ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** ���ʊ֐���O�n���h�� ***
--    WHEN global_api_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--    -- *** OTHERS��O�n���h�� ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
----
----#####################################  �Œ蕔 END   ##########################################
----
--  END set_reception_sum;
---- == 2009/04/06 V1.1 Added END   ===============================================================
--
  /**********************************************************************************
   * Procedure Name   : set_reception_sum
   * Description      : �݌v�󕥃f�[�^�o��(A-8)
   ***********************************************************************************/
  PROCEDURE set_reception_sum(
    it_base_code                IN xxcoi_inv_reception_daily.base_code%TYPE,                  -- 01.���_�R�[�h
    it_subinventory_code        IN xxcoi_inv_reception_daily.subinventory_code%TYPE,          -- 03.�ۊǏꏊ
    it_practice_date            IN xxcoi_inv_reception_daily.practice_date%TYPE,              -- 04.�N����
    it_inventory_item_id        IN xxcoi_inv_reception_daily.inventory_item_id%TYPE,          -- 05.�i��ID
    it_subinventory_type        IN xxcoi_inv_reception_daily.subinventory_type%TYPE,          -- 06.�ۊǏꏊ�敪
    it_operation_cost           IN xxcoi_inv_reception_daily.operation_cost%TYPE,             -- 07.�c�ƌ���
    it_standard_cost            IN xxcoi_inv_reception_daily.standard_cost%TYPE,              -- 08.�W������
    it_sales_shipped            IN xxcoi_inv_reception_daily.sales_shipped%TYPE,              -- 10.����o��
    it_sales_shipped_b          IN xxcoi_inv_reception_daily.sales_shipped_b%TYPE,            -- 11.����o�ɐU��
    it_return_goods             IN xxcoi_inv_reception_daily.return_goods%TYPE,               -- 12.�ԕi
    it_return_goods_b           IN xxcoi_inv_reception_daily.return_goods_b%TYPE,             -- 13.�ԕi�U��
    it_warehouse_ship           IN xxcoi_inv_reception_daily.warehouse_ship%TYPE,             -- 14.�q�ɂ֕Ԍ�
    it_truck_ship               IN xxcoi_inv_reception_daily.truck_ship%TYPE,                 -- 15.�c�ƎԂ֏o��
    it_others_ship              IN xxcoi_inv_reception_daily.others_ship%TYPE,                -- 16.���o�ɁQ���̑��o��
    it_warehouse_stock          IN xxcoi_inv_reception_daily.warehouse_stock%TYPE,            -- 17.�q�ɂ�����
    it_truck_stock              IN xxcoi_inv_reception_daily.truck_stock%TYPE,                -- 18.�c�ƎԂ�����
    it_others_stock             IN xxcoi_inv_reception_daily.others_stock%TYPE,               -- 19.���o�ɁQ���̑�����
    it_change_stock             IN xxcoi_inv_reception_daily.change_stock%TYPE,               -- 20.�q�֓���
    it_change_ship              IN xxcoi_inv_reception_daily.change_ship%TYPE,                -- 21.�q�֏o��
    it_goods_transfer_old       IN xxcoi_inv_reception_daily.goods_transfer_old%TYPE,         -- 22.���i�U�ցi�����i�j
    it_goods_transfer_new       IN xxcoi_inv_reception_daily.goods_transfer_new%TYPE,         -- 23.���i�U�ցi�V���i�j
    it_sample_quantity          IN xxcoi_inv_reception_daily.sample_quantity%TYPE,            -- 24.���{�o��
    it_sample_quantity_b        IN xxcoi_inv_reception_daily.sample_quantity_b%TYPE,          -- 25.���{�o�ɐU��
    it_customer_sample_ship     IN xxcoi_inv_reception_daily.customer_sample_ship%TYPE,       -- 26.�ڋq���{�o��
    it_customer_sample_ship_b   IN xxcoi_inv_reception_daily.customer_sample_ship_b%TYPE,     -- 27.�ڋq���{�o�ɐU��
    it_customer_support_ss      IN xxcoi_inv_reception_daily.customer_support_ss%TYPE,        -- 28.�ڋq���^���{�o��
    it_customer_support_ss_b    IN xxcoi_inv_reception_daily.customer_support_ss_b%TYPE,      -- 29.�ڋq���^���{�o�ɐU��
    it_vd_supplement_stock      IN xxcoi_inv_reception_daily.vd_supplement_stock%TYPE,        -- 32.����VD��[����
    it_vd_supplement_ship       IN xxcoi_inv_reception_daily.vd_supplement_ship%TYPE,         -- 33.����VD��[�o��
    it_inventory_change_in      IN xxcoi_inv_reception_daily.inventory_change_in%TYPE,        -- 34.��݌ɕύX����
    it_inventory_change_out     IN xxcoi_inv_reception_daily.inventory_change_out%TYPE,       -- 35.��݌ɕύX�o��
    it_factory_return           IN xxcoi_inv_reception_daily.factory_return%TYPE,             -- 36.�H��ԕi
    it_factory_return_b         IN xxcoi_inv_reception_daily.factory_return_b%TYPE,           -- 37.�H��ԕi�U��
    it_factory_change           IN xxcoi_inv_reception_daily.factory_change%TYPE,             -- 38.�H��q��
    it_factory_change_b         IN xxcoi_inv_reception_daily.factory_change_b%TYPE,           -- 39.�H��q�֐U��
    it_removed_goods            IN xxcoi_inv_reception_daily.removed_goods%TYPE,              -- 40.�p�p
    it_removed_goods_b          IN xxcoi_inv_reception_daily.removed_goods_b%TYPE,            -- 41.�p�p�U��
    it_factory_stock            IN xxcoi_inv_reception_daily.factory_stock%TYPE,              -- 42.�H�����
    it_factory_stock_b          IN xxcoi_inv_reception_daily.factory_stock_b%TYPE,            -- 43.�H����ɐU��
    it_ccm_sample_ship          IN xxcoi_inv_reception_daily.ccm_sample_ship%TYPE,            -- 30.�ڋq�L����`��A���Џ��i
    it_ccm_sample_ship_b        IN xxcoi_inv_reception_daily.ccm_sample_ship_b%TYPE,          -- 31.�ڋq�L����`��A���Џ��i�U��
    it_wear_decrease            IN xxcoi_inv_reception_daily.wear_decrease%TYPE,              -- 44.�I�����Ց�
    it_wear_increase            IN xxcoi_inv_reception_daily.wear_increase%TYPE,              -- 45.�I�����Ռ�
    it_selfbase_ship            IN xxcoi_inv_reception_daily.selfbase_ship%TYPE,              -- 46.�ۊǏꏊ�ړ��Q�����_�o��
    it_selfbase_stock           IN xxcoi_inv_reception_daily.selfbase_stock%TYPE,             -- 47.�ۊǏꏊ�ړ��Q�����_����
    it_book_inventory_quantity  IN xxcoi_inv_reception_daily.book_inventory_quantity%TYPE,    -- 48.����݌ɐ�
    ib_chk_result               IN BOOLEAN,                                                   -- 49.�݌ɉ�v����OPEN����
    ov_errbuf                   OUT VARCHAR2,                     -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode                  OUT VARCHAR2,                     -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg                   OUT VARCHAR2)                     -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_reception_sum'; -- �v���O������
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
    ln_dummy                    NUMBER;         -- �_�~�[�ϐ�
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
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    IF ((it_practice_date = gd_f_business_date)
        OR
        (    (it_practice_date = gd_f_max_practice_date)
         AND (ib_chk_result) 
        )
       )
    THEN
      BEGIN
        -- �����f�[�^�A�܂��́A�O���f�[�^�őO���̍݌ɉ�v���Ԃ�OPEN���Ă���ꍇ�ȉ������s
        -- ===================================
        --  1.�݌v�e�[�u�����b�N�擾
        -- ===================================
        SELECT  1
        INTO    ln_dummy
        FROM    xxcoi_inv_reception_sum   xirs
        WHERE   xirs.base_code            =   it_base_code
---- == 2009/08/26 V1.8 Added START ===============================================================
        AND     xirs.organization_id      =   gn_f_organization_id
---- == 2009/08/26 V1.8 Added END   ===============================================================
        AND     xirs.subinventory_code    =   it_subinventory_code
        AND     xirs.inventory_item_id    =   it_inventory_item_id
        AND     xirs.practice_date        =   SUBSTRB(TO_CHAR(it_practice_date, cv_date), 1, 6)
        AND     ROWNUM                    =   1
        FOR UPDATE NOWAIT;
        --
        -- ===================================
        --  2.�݌v�e�[�u���X�V
        -- ===================================
        -- ���b�N���擾���ꂽ�ꍇ�A���o�ɐ����X�V����
        UPDATE  xxcoi_inv_reception_sum
        SET     sales_shipped             = sales_shipped           + it_sales_shipped            -- 01.����o��
               ,sales_shipped_b           = sales_shipped_b         + it_sales_shipped_b          -- 02.����o�ɐU��
               ,return_goods              = return_goods            + it_return_goods             -- 03.�ԕi
               ,return_goods_b            = return_goods_b          + it_return_goods_b           -- 04.�ԕi�U��
               ,warehouse_ship            = warehouse_ship          + it_warehouse_ship           -- 05.�q�ɂ֕Ԍ�
               ,truck_ship                = truck_ship              + it_truck_ship               -- 06.�c�ƎԂ֏o��
               ,others_ship               = others_ship             + it_others_ship              -- 07.���o�ɁQ���̑��o��
               ,warehouse_stock           = warehouse_stock         + it_warehouse_stock          -- 08.�q�ɂ�����
               ,truck_stock               = truck_stock             + it_truck_stock              -- 09.�c�ƎԂ�����
               ,others_stock              = others_stock            + it_others_stock             -- 10.���o�ɁQ���̑�����
               ,change_stock              = change_stock            + it_change_stock             -- 11.�q�֓���
               ,change_ship               = change_ship             + it_change_ship              -- 12.�q�֏o��
               ,goods_transfer_old        = goods_transfer_old      + it_goods_transfer_old       -- 13.���i�U�ցi�����i�j
               ,goods_transfer_new        = goods_transfer_new      + it_goods_transfer_new       -- 14.���i�U�ցi�V���i�j
               ,sample_quantity           = sample_quantity         + it_sample_quantity          -- 15.���{�o��
               ,sample_quantity_b         = sample_quantity_b       + it_sample_quantity_b        -- 16.���{�o�ɐU��
               ,customer_sample_ship      = customer_sample_ship    + it_customer_sample_ship     -- 17.�ڋq���{�o��
               ,customer_sample_ship_b    = customer_sample_ship_b  + it_customer_sample_ship_b   -- 18.�ڋq���{�o�ɐU��
               ,customer_support_ss       = customer_support_ss     + it_customer_support_ss      -- 19.�ڋq���^���{�o��
               ,customer_support_ss_b     = customer_support_ss_b   + it_customer_support_ss_b    -- 20.�ڋq���^���{�o�ɐU��
               ,ccm_sample_ship           = ccm_sample_ship         + it_ccm_sample_ship          -- 21.�ڋq�L����`��A���Џ��i
               ,ccm_sample_ship_b         = ccm_sample_ship_b       + it_ccm_sample_ship_b        -- 22.�ڋq�L����`��A���Џ��i�U��
               ,vd_supplement_stock       = vd_supplement_stock     + it_vd_supplement_stock      -- 23.����VD��[����
               ,vd_supplement_ship        = vd_supplement_ship      + it_vd_supplement_ship       -- 24.����VD��[�o��
               ,inventory_change_in       = inventory_change_in     + it_inventory_change_in      -- 25.��݌ɕύX����
               ,inventory_change_out      = inventory_change_out    + it_inventory_change_out     -- 26.��݌ɕύX�o��
               ,factory_return            = factory_return          + it_factory_return           -- 27.�H��ԕi
               ,factory_return_b          = factory_return_b        + it_factory_return_b         -- 28.�H��ԕi�U��
               ,factory_change            = factory_change          + it_factory_change           -- 29.�H��q��
               ,factory_change_b          = factory_change_b        + it_factory_change_b         -- 30.�H��q�֐U��
               ,removed_goods             = removed_goods           + it_removed_goods            -- 31.�p�p
               ,removed_goods_b           = removed_goods_b         + it_removed_goods_b          -- 32.�p�p�U��
               ,factory_stock             = factory_stock           + it_factory_stock            -- 33.�H�����
               ,factory_stock_b           = factory_stock_b         + it_factory_stock_b          -- 34.�H����ɐU��
               ,wear_decrease             = wear_decrease           + it_wear_decrease            -- 35.�I�����Ց�
               ,wear_increase             = wear_increase           + it_wear_increase            -- 36.�I�����Ռ�
               ,selfbase_ship             = selfbase_ship           + it_selfbase_ship            -- 37.�ۊǏꏊ�ړ��Q�����_�o��
               ,selfbase_stock            = selfbase_stock          + it_selfbase_stock           -- 38.�ۊǏꏊ�ړ��Q�����_����
               ,book_inventory_quantity   = book_inventory_quantity + it_book_inventory_quantity  -- 39.����݌ɐ�
               ,last_updated_by           = cn_last_updated_by                                    -- 40.�ŏI�X�V��
               ,last_update_date          = SYSDATE                                               -- 41.�ŏI�X�V��
               ,last_update_login         = cn_last_update_login                                  -- 42.�ŏI�X�V���O�C��
               ,request_id                = cn_request_id                                         -- 43.�v��ID
               ,program_application_id    = cn_program_application_id                             -- 44.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
               ,program_id                = cn_program_id                                         -- 45.�R���J�����g�E�v���O����ID
               ,program_update_date       = SYSDATE                                               -- 46.�v���O�����X�V��
        WHERE   base_code                 = it_base_code
---- == 2009/08/26 V1.8 Added START ===============================================================
        AND     organization_id           = gn_f_organization_id
---- == 2009/08/26 V1.8 Added END   ===============================================================
        AND     subinventory_code         = it_subinventory_code
        AND     inventory_item_id         = it_inventory_item_id
        AND     practice_date             = SUBSTRB(TO_CHAR(it_practice_date, cv_date), 1, 6);
        --
---- == 2009/08/26 V1.8 Added START ===============================================================
        gn_target_cnt := gn_target_cnt + 1;
---- == 2009/08/26 V1.8 Added END   ===============================================================
      EXCEPTION
        WHEN  lock_error_expt THEN
          -- ���b�N���擾����Ȃ������ꍇ
          -- �����݌Ɏ󕥁i�݌v�j���b�N�G���[���b�Z�[�W
          lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application  => cv_short_name
                          ,iv_name         => cv_msg_xxcoi1_10378
                         );
          lv_errbuf   := lv_errmsg;
          RAISE global_process_expt;
          --
        WHEN NO_DATA_FOUND THEN
          -- ===================================
          --  3.�݌v�e�[�u���쐬
          -- ===================================
          -- �Ώۃf�[�^�����݂��Ȃ��ꍇ�A�݌v����V�K�쐬����
          INSERT INTO xxcoi_inv_reception_sum(
            base_code                                   -- 01.���_�R�[�h
           ,organization_id                             -- 02.�g�DID
           ,subinventory_code                           -- 03.�ۊǏꏊ
           ,subinventory_type                           -- 04.�ۊǏꏊ�敪
           ,practice_date                               -- 05.�N��
           ,inventory_item_id                           -- 06.�i��ID
           ,operation_cost                              -- 07.�c�ƌ���
           ,standard_cost                               -- 08.�W������
           ,sales_shipped                               -- 09.����o��
           ,sales_shipped_b                             -- 10.����o�ɐU��
           ,return_goods                                -- 11.�ԕi
           ,return_goods_b                              -- 12.�ԕi�U��
           ,warehouse_ship                              -- 13.�q�ɂ֕Ԍ�
           ,truck_ship                                  -- 14.�c�ƎԂ֏o��
           ,others_ship                                 -- 15.���o�ɁQ���̑��o��
           ,warehouse_stock                             -- 16.�q�ɂ�����
           ,truck_stock                                 -- 17.�c�ƎԂ�����
           ,others_stock                                -- 18.���o�ɁQ���̑�����
           ,change_stock                                -- 19.�q�֓���
           ,change_ship                                 -- 20.�q�֏o��
           ,goods_transfer_old                          -- 21.���i�U�ցi�����i�j
           ,goods_transfer_new                          -- 22.���i�U�ցi�V���i�j
           ,sample_quantity                             -- 23.���{�o��
           ,sample_quantity_b                           -- 24.���{�o�ɐU��
           ,customer_sample_ship                        -- 25.�ڋq���{�o��
           ,customer_sample_ship_b                      -- 26.�ڋq���{�o�ɐU��
           ,customer_support_ss                         -- 27.�ڋq���^���{�o��
           ,customer_support_ss_b                       -- 28.�ڋq���^���{�o�ɐU��
           ,ccm_sample_ship                             -- 29.�ڋq�L����`��A���Џ��i
           ,ccm_sample_ship_b                           -- 30.�ڋq�L����`��A���Џ��i�U��
           ,vd_supplement_stock                         -- 31.����VD��[����
           ,vd_supplement_ship                          -- 32.����VD��[�o��
           ,inventory_change_in                         -- 33.��݌ɕύX����
           ,inventory_change_out                        -- 34.��݌ɕύX�o��
           ,factory_return                              -- 35.�H��ԕi
           ,factory_return_b                            -- 36.�H��ԕi�U��
           ,factory_change                              -- 37.�H��q��
           ,factory_change_b                            -- 38.�H��q�֐U��
           ,removed_goods                               -- 39.�p�p
           ,removed_goods_b                             -- 40.�p�p�U��
           ,factory_stock                               -- 41.�H�����
           ,factory_stock_b                             -- 42.�H����ɐU��
           ,wear_decrease                               -- 43.�I�����Ց�
           ,wear_increase                               -- 44.�I�����Ռ�
           ,selfbase_ship                               -- 45.�ۊǏꏊ�ړ��Q�����_�o��
           ,selfbase_stock                              -- 46.�ۊǏꏊ�ړ��Q�����_����
           ,book_inventory_quantity                     -- 47.����݌ɐ�
           ,created_by                                  -- 48.�쐬��
           ,creation_date                               -- 49.�쐬��
           ,last_updated_by                             -- 50.�ŏI�X�V��
           ,last_update_date                            -- 51.�ŏI�X�V��
           ,last_update_login                           -- 52.�ŏI�X�V���O�C��
           ,request_id                                  -- 53.�v��ID
           ,program_application_id                      -- 54.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
           ,program_id                                  -- 55.�R���J�����g�E�v���O����ID
           ,program_update_date                         -- 56.�v���O�����X�V��
          )VALUES(
            it_base_code                      -- 01
           ,gn_f_organization_id              -- 02
           ,it_subinventory_code              -- 03
           ,it_subinventory_type              -- 04
           ,SUBSTRB(TO_CHAR(it_practice_date, cv_date), 1, 6)
                                              -- 05
           ,it_inventory_item_id              -- 06
           ,it_operation_cost                 -- 07
           ,it_standard_cost                  -- 08
           ,it_sales_shipped                  -- 09
           ,it_sales_shipped_b                -- 10
           ,it_return_goods                   -- 11
           ,it_return_goods_b                 -- 12
           ,it_warehouse_ship                 -- 13
           ,it_truck_ship                     -- 14
           ,it_others_ship                    -- 15
           ,it_warehouse_stock                -- 16
           ,it_truck_stock                    -- 17
           ,it_others_stock                   -- 18
           ,it_change_stock                   -- 19
           ,it_change_ship                    -- 20
           ,it_goods_transfer_old             -- 21
           ,it_goods_transfer_new             -- 22
           ,it_sample_quantity                -- 23
           ,it_sample_quantity_b              -- 24
           ,it_customer_sample_ship           -- 25
           ,it_customer_sample_ship_b         -- 26
           ,it_customer_support_ss            -- 27
           ,it_customer_support_ss_b          -- 28
           ,it_ccm_sample_ship                -- 29
           ,it_ccm_sample_ship_b              -- 30
           ,it_vd_supplement_stock            -- 31
           ,it_vd_supplement_ship             -- 32
           ,it_inventory_change_in            -- 33
           ,it_inventory_change_out           -- 34
           ,it_factory_return                 -- 35
           ,it_factory_return_b               -- 36
           ,it_factory_change                 -- 37
           ,it_factory_change_b               -- 38
           ,it_removed_goods                  -- 39
           ,it_removed_goods_b                -- 40
           ,it_factory_stock                  -- 41
           ,it_factory_stock_b                -- 42
           ,it_wear_decrease                  -- 43
           ,it_wear_increase                  -- 44
           ,it_selfbase_ship                  -- 45
           ,it_selfbase_stock                 -- 46
           ,it_book_inventory_quantity        -- 47
           ,cn_created_by                     -- 48
           ,SYSDATE                           -- 49
           ,cn_last_updated_by                -- 50
           ,SYSDATE                           -- 51
           ,cn_last_update_login              -- 52
           ,cn_request_id                     -- 53
           ,cn_program_application_id         -- 54
           ,cn_program_id                     -- 55
           ,SYSDATE                           -- 56
          );
          --
---- == 2009/08/26 V1.8 Added START ===============================================================
          gn_target_cnt := gn_target_cnt + 1;
---- == 2009/08/26 V1.8 Added END   ===============================================================
      END;
    END IF;
    --
    --
    IF (it_practice_date = gd_f_max_practice_date) THEN
      -- �O���f�[�^�̏ꍇ�ȉ������s
      BEGIN
        -- ===================================
        --  4.�݌v�e�[�u�����b�N�擾
        -- ===================================
        SELECT  1
        INTO    ln_dummy
        FROM    xxcoi_inv_reception_sum   xirs
        WHERE   xirs.base_code            =   it_base_code
---- == 2009/08/26 V1.8 Added START ===============================================================
        AND     xirs.organization_id      =   gn_f_organization_id
---- == 2009/08/26 V1.8 Added END   ===============================================================
        AND     xirs.subinventory_code    =   it_subinventory_code
        AND     xirs.inventory_item_id    =   it_inventory_item_id
        AND     xirs.practice_date        =   SUBSTRB(TO_CHAR(gd_f_business_date, cv_date), 1, 6)
        AND     ROWNUM                    =   1
        FOR UPDATE NOWAIT;
        --
        -- =======================================
        --  5.�݌v�e�[�u���X�V(�O�����𓖌��ɔ��f)
        -- =======================================
        -- ���b�N���擾���ꂽ�ꍇ�A���o�ɐ����X�V����
        UPDATE  xxcoi_inv_reception_sum
        SET     book_inventory_quantity   = book_inventory_quantity + it_book_inventory_quantity            -- 39.����݌ɐ�
               ,last_updated_by           = cn_last_updated_by                                              -- 40.�ŏI�X�V��
               ,last_update_date          = SYSDATE                                                         -- 41.�ŏI�X�V��
               ,last_update_login         = cn_last_update_login                                            -- 42.�ŏI�X�V���O�C��
               ,request_id                = cn_request_id                                                   -- 43.�v��ID
               ,program_application_id    = cn_program_application_id                                       -- 44.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
               ,program_id                = cn_program_id                                                   -- 45.�R���J�����g�E�v���O����ID
               ,program_update_date       = SYSDATE                                                         -- 46.�v���O�����X�V��
        WHERE   base_code                 = it_base_code
---- == 2009/08/26 V1.8 Added START ===============================================================
        AND     organization_id           = gn_f_organization_id
---- == 2009/08/26 V1.8 Added END   ===============================================================
        AND     subinventory_code         = it_subinventory_code
        AND     inventory_item_id         = it_inventory_item_id
        AND     practice_date             = SUBSTRB(TO_CHAR(gd_f_business_date, cv_date), 1, 6);
        --
      EXCEPTION
        WHEN  lock_error_expt THEN
          -- ���b�N���擾����Ȃ������ꍇ
          -- �����݌Ɏ󕥁i�݌v�j���b�N�G���[���b�Z�[�W
          lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application  => cv_short_name
                          ,iv_name         => cv_msg_xxcoi1_10378
                         );
          lv_errbuf   := lv_errmsg;
          RAISE global_process_expt;
          --
        WHEN NO_DATA_FOUND THEN
          -- =======================================
          --  6.�݌v�e�[�u���쐬(�O�����𓖌��ɔ��f)
          -- =======================================
          -- �Ώۃf�[�^�����݂��Ȃ��ꍇ�A�݌v����V�K�쐬����
          INSERT INTO xxcoi_inv_reception_sum(
            base_code                                   -- 01.���_�R�[�h
           ,organization_id                             -- 02.�g�DID
           ,subinventory_code                           -- 03.�ۊǏꏊ
           ,subinventory_type                           -- 04.�ۊǏꏊ�敪
           ,practice_date                               -- 05.�N��
           ,inventory_item_id                           -- 06.�i��ID
           ,operation_cost                              -- 07.�c�ƌ���
           ,standard_cost                               -- 08.�W������
           ,sales_shipped                               -- 09.����o��
           ,sales_shipped_b                             -- 10.����o�ɐU��
           ,return_goods                                -- 11.�ԕi
           ,return_goods_b                              -- 12.�ԕi�U��
           ,warehouse_ship                              -- 13.�q�ɂ֕Ԍ�
           ,truck_ship                                  -- 14.�c�ƎԂ֏o��
           ,others_ship                                 -- 15.���o�ɁQ���̑��o��
           ,warehouse_stock                             -- 16.�q�ɂ�����
           ,truck_stock                                 -- 17.�c�ƎԂ�����
           ,others_stock                                -- 18.���o�ɁQ���̑�����
           ,change_stock                                -- 19.�q�֓���
           ,change_ship                                 -- 20.�q�֏o��
           ,goods_transfer_old                          -- 21.���i�U�ցi�����i�j
           ,goods_transfer_new                          -- 22.���i�U�ցi�V���i�j
           ,sample_quantity                             -- 23.���{�o��
           ,sample_quantity_b                           -- 24.���{�o�ɐU��
           ,customer_sample_ship                        -- 25.�ڋq���{�o��
           ,customer_sample_ship_b                      -- 26.�ڋq���{�o�ɐU��
           ,customer_support_ss                         -- 27.�ڋq���^���{�o��
           ,customer_support_ss_b                       -- 28.�ڋq���^���{�o�ɐU��
           ,ccm_sample_ship                             -- 29.�ڋq�L����`��A���Џ��i
           ,ccm_sample_ship_b                           -- 30.�ڋq�L����`��A���Џ��i�U��
           ,vd_supplement_stock                         -- 31.����VD��[����
           ,vd_supplement_ship                          -- 32.����VD��[�o��
           ,inventory_change_in                         -- 33.��݌ɕύX����
           ,inventory_change_out                        -- 34.��݌ɕύX�o��
           ,factory_return                              -- 35.�H��ԕi
           ,factory_return_b                            -- 36.�H��ԕi�U��
           ,factory_change                              -- 37.�H��q��
           ,factory_change_b                            -- 38.�H��q�֐U��
           ,removed_goods                               -- 39.�p�p
           ,removed_goods_b                             -- 40.�p�p�U��
           ,factory_stock                               -- 41.�H�����
           ,factory_stock_b                             -- 42.�H����ɐU��
           ,wear_decrease                               -- 43.�I�����Ց�
           ,wear_increase                               -- 44.�I�����Ռ�
           ,selfbase_ship                               -- 45.�ۊǏꏊ�ړ��Q�����_�o��
           ,selfbase_stock                              -- 46.�ۊǏꏊ�ړ��Q�����_����
           ,book_inventory_quantity                     -- 47.����݌ɐ�
           ,created_by                                  -- 48.�쐬��
           ,creation_date                               -- 49.�쐬��
           ,last_updated_by                             -- 50.�ŏI�X�V��
           ,last_update_date                            -- 51.�ŏI�X�V��
           ,last_update_login                           -- 52.�ŏI�X�V���O�C��
           ,request_id                                  -- 53.�v��ID
           ,program_application_id                      -- 54.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
           ,program_id                                  -- 55.�R���J�����g�E�v���O����ID
           ,program_update_date                         -- 56.�v���O�����X�V��
          )VALUES(
            it_base_code                      -- 01
           ,gn_f_organization_id              -- 02
           ,it_subinventory_code              -- 03
           ,it_subinventory_type              -- 04
           ,SUBSTRB(TO_CHAR(gd_f_business_date, cv_date), 1, 6)
                                              -- 05
           ,it_inventory_item_id              -- 06
           ,it_operation_cost                 -- 07
           ,it_standard_cost                  -- 08
           ,0                                 -- 09
           ,0                                 -- 10
           ,0                                 -- 11
           ,0                                 -- 12
           ,0                                 -- 13
           ,0                                 -- 14
           ,0                                 -- 15
           ,0                                 -- 16
           ,0                                 -- 17
           ,0                                 -- 18
           ,0                                 -- 19
           ,0                                 -- 20
           ,0                                 -- 21
           ,0                                 -- 22
           ,0                                 -- 23
           ,0                                 -- 24
           ,0                                 -- 25
           ,0                                 -- 26
           ,0                                 -- 27
           ,0                                 -- 28
           ,0                                 -- 29
           ,0                                 -- 30
           ,0                                 -- 31
           ,0                                 -- 32
           ,0                                 -- 33
           ,0                                 -- 34
           ,0                                 -- 35
           ,0                                 -- 36
           ,0                                 -- 37
           ,0                                 -- 38
           ,0                                 -- 39
           ,0                                 -- 40
           ,0                                 -- 41
           ,0                                 -- 42
           ,0                                 -- 43
           ,0                                 -- 44
           ,0                                 -- 45
           ,0                                 -- 46
           ,it_book_inventory_quantity        -- 47
           ,cn_created_by                     -- 48
           ,SYSDATE                           -- 49
           ,cn_last_updated_by                -- 50
           ,SYSDATE                           -- 51
           ,cn_last_update_login              -- 52
           ,cn_request_id                     -- 53
           ,cn_program_application_id         -- 54
           ,cn_program_id                     -- 55
           ,SYSDATE                           -- 56
          );
          --
---- == 2009/08/26 V1.8 Added START ===============================================================
          gn_target_cnt := gn_target_cnt + 1;
---- == 2009/08/26 V1.8 Added END   ===============================================================
      END;
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
  END set_reception_sum;
-- == 2009/05/28 V1.4 Modified END   ===============================================================
-- == 2009/05/28 V1.4 Added START ===============================================================
  /**********************************************************************************
   * Procedure Name   : set_last_daily_sum
   * Description      : �O���T�}�����o��(A-7)
   ***********************************************************************************/
  PROCEDURE set_last_daily_sum(
    ov_errbuf         OUT VARCHAR2,                     -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode        OUT VARCHAR2,                     -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg         OUT VARCHAR2)                     -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_last_daily_sum'; -- �v���O������
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
-- == 2009/08/31 V1.9 Added START ===============================================================
    lt_standard_cost      xxcoi_inv_reception_sum.standard_cost%TYPE;
    lt_operation_cost     xxcoi_inv_reception_sum.operation_cost%TYPE;
-- == 2009/08/31 V1.9 Added START ===============================================================
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
    CURSOR  daily_sum_cur
    IS
      SELECT  xirs.base_code
             ,xirs.organization_id
             ,xirs.subinventory_code
             ,xirs.inventory_item_id
             ,xirs.subinventory_type
             ,xirs.operation_cost
             ,xirs.standard_cost
             ,xirs.book_inventory_quantity
      FROM    xxcoi_inv_reception_sum   xirs
      WHERE   xirs.organization_id  = gn_f_organization_id
      AND     xirs.practice_date    = SUBSTRB(TO_CHAR(ADD_MONTHS(gd_f_business_date, -1), cv_date), 1, 6);
    --
    -- <�J�[�\����>���R�[�h�^
    daily_sum_rec     daily_sum_cur%ROWTYPE;
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
    -- ===================================
    --  1.�O���T�}�����R�s�[
    -- ===================================
    <<set_last_sum_loop>>
    FOR daily_sum_rec  IN  daily_sum_cur  LOOP
-- == 2009/08/31 V1.9 Added START ===============================================================
      -- ===================================
      --  2.�W�������擾
      -- ===================================
      xxcoi_common_pkg.get_cmpnt_cost(
        in_item_id      =>  daily_sum_rec.inventory_item_id                 -- �i��ID
       ,in_org_id       =>  gn_f_organization_id                            -- �g�DID
       ,id_period_date  =>  gd_f_business_date                              -- �Ώۓ�
       ,ov_cmpnt_cost   =>  lt_standard_cost                                -- �W������
       ,ov_errbuf       =>  lv_errbuf                                       -- �G���[���b�Z�[�W
       ,ov_retcode      =>  lv_retcode                                      -- ���^�[���E�R�[�h
       ,ov_errmsg       =>  lv_errmsg                                       -- ���[�U�[�E�G���[���b�Z�[�W
      );
      -- �I���p�����[�^����
      IF (lv_retcode = cv_status_error) THEN
        lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_short_name
                        ,iv_name         => cv_msg_xxcoi1_10285
                       );
        lv_errbuf   := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      --
      -- ===================================
      --  2.�c�ƌ����擾
      -- ===================================
      xxcoi_common_pkg.get_discrete_cost(
        in_item_id        =>  daily_sum_rec.inventory_item_id                 -- �i��ID
       ,in_org_id         =>  gn_f_organization_id                            -- �g�DID
       ,id_target_date    =>  gd_f_business_date                              -- �Ώۓ�
       ,ov_discrete_cost  =>  lt_operation_cost                               -- �c�ƌ���
       ,ov_errbuf         =>  lv_errbuf                                       -- �G���[���b�Z�[�W
       ,ov_retcode        =>  lv_retcode                                      -- ���^�[���E�R�[�h
       ,ov_errmsg         =>  lv_errmsg                                       -- ���[�U�[�E�G���[���b�Z�[�W
      );
      -- �I���p�����[�^����
      IF (lv_retcode = cv_status_error) THEN
        lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_short_name
                        ,iv_name         => cv_msg_xxcoi1_10293
                       );
        lv_errbuf   := lv_errmsg;
        RAISE global_api_expt;
      END IF;
-- == 2009/08/31 V1.9 Added END   ===============================================================
--
      INSERT INTO xxcoi_inv_reception_sum(
        base_code                                   -- 01.���_�R�[�h
       ,organization_id                             -- 02.�g�DID
       ,subinventory_code                           -- 03.�ۊǏꏊ
       ,subinventory_type                           -- 04.�ۊǏꏊ�敪
       ,practice_date                               -- 05.�N��
       ,inventory_item_id                           -- 06.�i��ID
       ,operation_cost                              -- 07.�c�ƌ���
       ,standard_cost                               -- 08.�W������
       ,sales_shipped                               -- 09.����o��
       ,sales_shipped_b                             -- 10.����o�ɐU��
       ,return_goods                                -- 11.�ԕi
       ,return_goods_b                              -- 12.�ԕi�U��
       ,warehouse_ship                              -- 13.�q�ɂ֕Ԍ�
       ,truck_ship                                  -- 14.�c�ƎԂ֏o��
       ,others_ship                                 -- 15.���o�ɁQ���̑��o��
       ,warehouse_stock                             -- 16.�q�ɂ�����
       ,truck_stock                                 -- 17.�c�ƎԂ�����
       ,others_stock                                -- 18.���o�ɁQ���̑�����
       ,change_stock                                -- 19.�q�֓���
       ,change_ship                                 -- 20.�q�֏o��
       ,goods_transfer_old                          -- 21.���i�U�ցi�����i�j
       ,goods_transfer_new                          -- 22.���i�U�ցi�V���i�j
       ,sample_quantity                             -- 23.���{�o��
       ,sample_quantity_b                           -- 24.���{�o�ɐU��
       ,customer_sample_ship                        -- 25.�ڋq���{�o��
       ,customer_sample_ship_b                      -- 26.�ڋq���{�o�ɐU��
       ,customer_support_ss                         -- 27.�ڋq���^���{�o��
       ,customer_support_ss_b                       -- 28.�ڋq���^���{�o�ɐU��
       ,ccm_sample_ship                             -- 29.�ڋq�L����`��A���Џ��i
       ,ccm_sample_ship_b                           -- 30.�ڋq�L����`��A���Џ��i�U��
       ,vd_supplement_stock                         -- 31.����VD��[����
       ,vd_supplement_ship                          -- 32.����VD��[�o��
       ,inventory_change_in                         -- 33.��݌ɕύX����
       ,inventory_change_out                        -- 34.��݌ɕύX�o��
       ,factory_return                              -- 35.�H��ԕi
       ,factory_return_b                            -- 36.�H��ԕi�U��
       ,factory_change                              -- 37.�H��q��
       ,factory_change_b                            -- 38.�H��q�֐U��
       ,removed_goods                               -- 39.�p�p
       ,removed_goods_b                             -- 40.�p�p�U��
       ,factory_stock                               -- 41.�H�����
       ,factory_stock_b                             -- 42.�H����ɐU��
       ,wear_decrease                               -- 43.�I�����Ց�
       ,wear_increase                               -- 44.�I�����Ռ�
       ,selfbase_ship                               -- 45.�ۊǏꏊ�ړ��Q�����_�o��
       ,selfbase_stock                              -- 46.�ۊǏꏊ�ړ��Q�����_����
       ,book_inventory_quantity                     -- 47.����݌ɐ�
       ,created_by                                  -- 48.�쐬��
       ,creation_date                               -- 49.�쐬��
       ,last_updated_by                             -- 50.�ŏI�X�V��
       ,last_update_date                            -- 51.�ŏI�X�V��
       ,last_update_login                           -- 52.�ŏI�X�V���O�C��
       ,request_id                                  -- 53.�v��ID
       ,program_application_id                      -- 54.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
       ,program_id                                  -- 55.�R���J�����g�E�v���O����ID
       ,program_update_date                         -- 56.�v���O�����X�V��
      )VALUES(
        daily_sum_rec.base_code                                 -- 01
       ,daily_sum_rec.organization_id                           -- 02
       ,daily_sum_rec.subinventory_code                         -- 03
       ,daily_sum_rec.subinventory_type                         -- 04
       ,SUBSTRB(TO_CHAR(gd_f_business_date, cv_date), 1, 6)     -- 05
       ,daily_sum_rec.inventory_item_id                         -- 06
-- == 2009/08/31 V1.9 Modified START ===============================================================
--       ,daily_sum_rec.operation_cost
--       ,daily_sum_rec.standard_cost
       ,lt_operation_cost                                       -- 07
       ,lt_standard_cost                                        -- 08
-- == 2009/08/31 V1.9 Modified END   ===============================================================
       ,0                                                       -- 09
       ,0                                                       -- 10
       ,0                                                       -- 11
       ,0                                                       -- 12
       ,0                                                       -- 13
       ,0                                                       -- 14
       ,0                                                       -- 15
       ,0                                                       -- 16
       ,0                                                       -- 17
       ,0                                                       -- 18
       ,0                                                       -- 19
       ,0                                                       -- 20
       ,0                                                       -- 21
       ,0                                                       -- 22
       ,0                                                       -- 23
       ,0                                                       -- 24
       ,0                                                       -- 25
       ,0                                                       -- 26
       ,0                                                       -- 27
       ,0                                                       -- 28
       ,0                                                       -- 29
       ,0                                                       -- 30
       ,0                                                       -- 31
       ,0                                                       -- 32
       ,0                                                       -- 33
       ,0                                                       -- 34
       ,0                                                       -- 35
       ,0                                                       -- 36
       ,0                                                       -- 37
       ,0                                                       -- 38
       ,0                                                       -- 39
       ,0                                                       -- 40
       ,0                                                       -- 41
       ,0                                                       -- 42
       ,0                                                       -- 43
       ,0                                                       -- 44
       ,0                                                       -- 45
       ,0                                                       -- 46
       ,daily_sum_rec.book_inventory_quantity                   -- 47
       ,cn_created_by                                           -- 48
       ,SYSDATE                                                 -- 49
       ,cn_last_updated_by                                      -- 50
       ,SYSDATE                                                 -- 51
       ,cn_last_update_login                                    -- 52
       ,cn_request_id                                           -- 53
       ,cn_program_application_id                               -- 54
       ,cn_program_id                                           -- 55
       ,SYSDATE                                                 -- 56
      );
---- == 2009/08/26 V1.8 Added START ===============================================================
      gn_target_cnt := gn_target_cnt + 1;
---- == 2009/08/26 V1.8 Added END   ===============================================================
    END LOOP set_last_sum_loop;
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
  END set_last_daily_sum;
-- == 2009/05/28 V1.4 Added END   ===============================================================
--
--
  /**********************************************************************************
   * Procedure Name   : upd_last_transaction_id
   * Description      : �ŏI���ID�X�V(A-6)
   ***********************************************************************************/
  PROCEDURE upd_last_transaction_id(
    ov_errbuf         OUT VARCHAR2,                     -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode        OUT VARCHAR2,                     -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg         OUT VARCHAR2)                     -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_last_transaction_id'; -- �v���O������
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
    IF (gn_f_last_transaction_id = 0) THEN
      INSERT INTO xxcoi_cooperation_control(
        control_id                      -- 01.����ID
       ,last_cooperation_date           -- 02.�ŏI�A�g����
       ,transaction_id                  -- 03.���ID
       ,program_short_name              -- 04.�v���O��������
       ,last_update_date                -- 05.�ŏI�X�V��
       ,last_updated_by                 -- 06.�ŏI�X�V��
       ,creation_date                   -- 07.�쐬��
       ,created_by                      -- 08.�쐬��
       ,last_update_login               -- 09.�ŏI�X�V���[�U
       ,request_id                      -- 10.�v��ID
       ,program_application_id          -- 11.�v���O�����A�v���P�[�V����ID
       ,program_id                      -- 12.�v���O����ID
       ,program_update_date             -- 13.�v���O�����X�V��
      )VALUES(
-- == 2009/08/26 V1.8 Modified START ===============================================================
--        cn_control_id                   -- 01
        DECODE(gv_exec_flag, cv_0, cn_control_id
                                 , cn_control_id2)
                                        -- 01
-- == 2009/08/26 V1.8 Modified END   ===============================================================
       ,gd_f_business_date              -- 02
       ,gn_f_max_transaction_id         -- 03
-- == 2009/08/26 V1.8 Modified START ===============================================================
--       ,cv_pgsname_a09c                 -- 04
       ,DECODE(gv_exec_flag, cv_0, cv_pgsname_a09c
                                 , cv_pgsname_b09c)
                                        -- 04
-- == 2009/08/26 V1.8 Modified END   ===============================================================
       ,SYSDATE                         -- 05
       ,cn_last_updated_by              -- 06
       ,SYSDATE                         -- 07
       ,cn_created_by                   -- 08
       ,cn_last_update_login            -- 09
       ,cn_request_id                   -- 10
       ,cn_program_application_id       -- 11
       ,cn_program_id                   -- 12
       ,SYSDATE                         -- 13
      );
      --
    ELSE
      UPDATE  xxcoi_cooperation_control
      SET     last_cooperation_date       =   gd_f_business_date            -- �ŏI�A�g����
             ,transaction_id              =   gn_f_max_transaction_id       -- ���ID
             ,last_update_date            =   SYSDATE                       -- �ŏI�X�V��
             ,last_updated_by             =   cn_last_updated_by            -- �ŏI�X�V��
             ,last_update_login           =   cn_last_update_login          -- �ŏI�X�V���[�U
             ,request_id                  =   cn_request_id                 -- �v��ID
             ,program_application_id      =   cn_program_application_id     -- �v���O�����A�v���P�[�V����ID
             ,program_id                  =   cn_program_id                 -- �v���O����ID
             ,program_update_date         =   SYSDATE                       -- �v���O�����X�V��
-- == 2009/08/26 V1.8 Modified START ===============================================================
--      WHERE   control_id            =   cn_control_id
--      AND     program_short_name    =   cv_pgsname_a09c;
      WHERE   control_id            =   DECODE(gv_exec_flag, cv_0, cn_control_id
                                                                 , cn_control_id2)
      AND     program_short_name    =   DECODE(gv_exec_flag, cv_0, cv_pgsname_a09c
                                                                 , cv_pgsname_b09c);
-- == 2009/08/26 V1.8 Modified END   ===============================================================
      --
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
  END upd_last_transaction_id;
--
  /**********************************************************************************
   * Procedure Name   : set_mtl_transaction_data
   * Description      : �����f�[�^�����݌Ɏ󕥁i�����j�o��(A-2, A-3)
   ***********************************************************************************/
  PROCEDURE set_mtl_transaction_data(
    ov_errbuf         OUT VARCHAR2,                     -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode        OUT VARCHAR2,                     -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg         OUT VARCHAR2)                     -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_mtl_transaction_data'; -- �v���O������
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
    lb_chk_result                   BOOLEAN;        -- �݌ɉ�v����OPEN�t���O�iOPEN:TRUE, CLOSE:FALSE�j
    ln_dummy                        NUMBER;         -- �_�~�[�ϐ�
    ln_material_flag                NUMBER  := 0;   -- ���ގ���f�[�^�擾�t���O
    ln_today_data                   NUMBER  := 0;   -- ���ގ���������f�[�^����
    --
    lt_base_code                    xxcoi_inv_reception_daily.base_code%TYPE;               -- ���_�R�[�h
    lt_subinventory_code            xxcoi_inv_reception_daily.subinventory_code%TYPE;       -- �ۊǏꏊ�R�[�h
    lt_inventory_item_id            xxcoi_inv_reception_daily.inventory_item_id%TYPE;       -- �i��ID
    lv_transaction_month            VARCHAR2(6);                                            -- ����N��
    lt_transaction_date             mtl_material_transactions.transaction_date%TYPE;        -- �����
    lt_last_book_inv_quantity       xxcoi_inv_reception_daily.book_inventory_quantity%TYPE; -- ����݌Ɂi�����j
    lt_today_book_inv_quantity      xxcoi_inv_reception_daily.book_inventory_quantity%TYPE; -- ����݌Ɂi�O���j
    lt_subinventory_type            xxcoi_inv_reception_daily.subinventory_type%TYPE;       -- �ۊǏꏊ�敪
    lt_standard_cost                xxcoi_inv_reception_daily.standard_cost%TYPE;           -- �W������
    lt_operation_cost               xxcoi_inv_reception_daily.operation_cost%TYPE;          -- �c�ƌ���
    lt_sales_shipped                xxcoi_inv_reception_daily.sales_shipped%TYPE;           -- ����o��
    lt_sales_shipped_b              xxcoi_inv_reception_daily.sales_shipped_b%TYPE;         -- ����o�ɐU��
    lt_return_goods                 xxcoi_inv_reception_daily.return_goods%TYPE;            -- �ԕi
    lt_return_goods_b               xxcoi_inv_reception_daily.return_goods_b%TYPE;          -- �ԕi�U��
    lt_warehouse_ship               xxcoi_inv_reception_daily.warehouse_ship%TYPE;          -- �q�ɂ֕Ԍ�
    lt_truck_ship                   xxcoi_inv_reception_daily.truck_ship%TYPE;              -- �c�ƎԂ֏o��
    lt_others_ship                  xxcoi_inv_reception_daily.others_ship%TYPE;             -- ���o�ɁQ���̑��o��
    lt_warehouse_stock              xxcoi_inv_reception_daily.warehouse_stock%TYPE;         -- �q�ɂ�����
    lt_truck_stock                  xxcoi_inv_reception_daily.truck_stock%TYPE;             -- �c�ƎԂ�����
    lt_others_stock                 xxcoi_inv_reception_daily.others_stock%TYPE;            -- ���o�ɁQ���̑�����
    lt_change_stock                 xxcoi_inv_reception_daily.change_stock%TYPE;            -- �q�֓���
    lt_change_ship                  xxcoi_inv_reception_daily.change_ship%TYPE;             -- �q�֏o��
    lt_goods_transfer_old           xxcoi_inv_reception_daily.goods_transfer_old%TYPE;      -- ���i�U�ցi�����i�j
    lt_goods_transfer_new           xxcoi_inv_reception_daily.goods_transfer_new%TYPE;      -- ���i�U�ցi�V���i�j
    lt_sample_quantity              xxcoi_inv_reception_daily.sample_quantity%TYPE;         -- ���{�o��
    lt_sample_quantity_b            xxcoi_inv_reception_daily.sample_quantity_b%TYPE;       -- ���{�o�ɐU��
    lt_customer_sample_ship         xxcoi_inv_reception_daily.customer_sample_ship%TYPE;    -- �ڋq���{�o��
    lt_customer_sample_ship_b       xxcoi_inv_reception_daily.customer_sample_ship_b%TYPE;  -- �ڋq���{�o�ɐU��
    lt_customer_support_ss          xxcoi_inv_reception_daily.customer_support_ss%TYPE;     -- �ڋq���^���{�o��
    lt_customer_support_ss_b        xxcoi_inv_reception_daily.customer_support_ss_b%TYPE;   -- �ڋq���^���{�o�ɐU��
    lt_vd_supplement_stock          xxcoi_inv_reception_daily.vd_supplement_stock%TYPE;     -- ����VD��[����
    lt_vd_supplement_ship           xxcoi_inv_reception_daily.vd_supplement_ship%TYPE;      -- ����VD��[�o��
    lt_inventory_change_in          xxcoi_inv_reception_daily.inventory_change_in%TYPE;     -- ��݌ɕύX����
    lt_inventory_change_out         xxcoi_inv_reception_daily.inventory_change_out%TYPE;    -- ��݌ɕύX�o��
    lt_factory_return               xxcoi_inv_reception_daily.factory_return%TYPE;          -- �H��ԕi
    lt_factory_return_b             xxcoi_inv_reception_daily.factory_return_b%TYPE;        -- �H��ԕi�U��
    lt_factory_change               xxcoi_inv_reception_daily.factory_change%TYPE;          -- �H��q��
    lt_factory_change_b             xxcoi_inv_reception_daily.factory_change_b%TYPE;        -- �H��q�֐U��
    lt_removed_goods                xxcoi_inv_reception_daily.removed_goods%TYPE;           -- �p�p
    lt_removed_goods_b              xxcoi_inv_reception_daily.removed_goods_b%TYPE;         -- �p�p�U��
    lt_factory_stock                xxcoi_inv_reception_daily.factory_stock%TYPE;           -- �H�����
    lt_factory_stock_b              xxcoi_inv_reception_daily.factory_stock_b%TYPE;         -- �H����ɐU��
    lt_ccm_sample_ship              xxcoi_inv_reception_daily.ccm_sample_ship%TYPE;         -- �ڋq�L����`��A���Џ��i
    lt_ccm_sample_ship_b            xxcoi_inv_reception_daily.ccm_sample_ship_b%TYPE;       -- �ڋq�L����`��A���Џ��i�U��
    lt_wear_decrease                xxcoi_inv_reception_daily.wear_decrease%TYPE;           -- �I�����Ց�
    lt_wear_increase                xxcoi_inv_reception_daily.wear_increase%TYPE;           -- �I�����Ռ�
    lt_selfbase_ship                xxcoi_inv_reception_daily.selfbase_ship%TYPE;           -- �ۊǏꏊ�ړ��Q�����_�o��
    lt_selfbase_stock               xxcoi_inv_reception_daily.selfbase_stock%TYPE;          -- �ۊǏꏊ�ړ��Q�����_����
    lt_book_inventory_quantity      xxcoi_inv_reception_daily.book_inventory_quantity%TYPE; -- ����݌ɐ�
-- == 2009/08/26 V1.8 Deleted START ===============================================================
---- == 2009/05/28 V1.4 Added START ===============================================================
--    lt_practice_date                xxcoi_inv_reception_daily.practice_date%TYPE;             -- �N��
---- == 2009/05/28 V1.4 Added START ===============================================================
-- == 2009/08/26 V1.8 Deleted END   ===============================================================
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���ގ���f�[�^�擾
    CURSOR  material_transaction_cur
    IS
-- == 2009/08/26 V1.8 Modified START ===============================================================
--      SELECT  msi1.attribute7                         base_code                   -- ���_�R�[�h
      SELECT  /*+ LEADING(MMT)
                  USE_NL(MMT MSI1 MTT)
                  USE_NL(MMT MSI2)
                  USE_NL(MMT xird_last)
                  USE_NL(MMT xird_today)
                  INDEX(MMT MTL_MATERIAL_TRANSACTIONS_U1)
                  */
              msi1.attribute7                         base_code                   -- ���_�R�[�h
-- == 2009/08/26 V1.8 Modified END   ===============================================================
             ,msi1.attribute1                         inventory_type              -- �ۊǏꏊ�敪
             ,msi2.attribute7                         sub_base_code               -- ����拒�_�R�[�h
             ,msi2.attribute1                         subinventory_type           -- �����ۊǏꏊ�敪
             ,mmt.subinventory_code                   subinventory_code           -- �ۊǏꏊ�R�[�h
             ,mtt.attribute3                          transaction_type            -- �󕥕\�W�v�L�[
             ,mmt.inventory_item_id                   inventory_item_id           -- �i��ID
             ,TO_CHAR(mmt.transaction_date, cv_month) transaction_month           -- ����N��
             ,TRUNC(mmt.transaction_date)             transaction_date            -- �����
-- == 2009/07/30 V1.7 Modified START ===============================================================
--             ,mmt.transaction_quantity                transaction_qty             -- �������
             ,mmt.primary_quantity                    transaction_qty             -- ��P�ʐ���
-- == 2009/07/30 V1.7 Modified END   ===============================================================
             ,xird_last.book_inventory_quantity       last_book_inv_quantity      -- ����݌ɐ��i�O���j
             ,xird_today.book_inventory_quantity      today_book_inv_quantity     -- ����݌ɐ��i�����j
-- == 2009/06/04 V1.5 Added START ===============================================================
             ,msi1.attribute13                        subinv_class                -- �ۊǏꏊ����
-- == 2009/06/04 V1.5 Added END   ===============================================================
      FROM    mtl_material_transactions     mmt                                   -- ���ގ���e�[�u��
             ,mtl_secondary_inventories     msi1                                  -- �ۊǏꏊ
             ,mtl_secondary_inventories     msi2                                  -- �ۊǏꏊ
             ,xxcoi_inv_reception_daily     xird_last                             -- �����݌Ɏ󕥕\�i�����j�i�O�����j
             ,xxcoi_inv_reception_daily     xird_today                            -- �����݌Ɏ󕥕\�i�����j�i�������j
             ,mtl_transaction_types         mtt                                   -- ����^�C�v�}�X�^
      WHERE   mmt.organization_id         =   gn_f_organization_id
      AND     mmt.transaction_id          >   gn_f_last_transaction_id
      AND     mmt.transaction_id         <=   gn_f_max_transaction_id
      AND     TRUNC(mmt.transaction_date)
                  BETWEEN TO_DATE(TO_CHAR(ADD_MONTHS(gd_f_business_date, -1), cv_month) || '01', cv_date)
                  AND     gd_f_business_date
      AND     mmt.subinventory_code       =   msi1.secondary_inventory_name
      AND     mmt.organization_id         =   msi1.organization_id
      AND     mmt.transfer_subinventory   =   msi2.secondary_inventory_name(+)
-- == 2009/08/26 V1.8 Added START ===============================================================
      AND     mmt.transfer_organization_id  =  msi2.organization_id(+)
-- == 2009/08/26 V1.8 Added END   ===============================================================
      AND     msi1.attribute1            <>   cv_inv_type_5
      AND     msi1.attribute1            <>   cv_inv_type_8
      AND     mmt.organization_id         =   xird_last.organization_id(+)
      AND     mmt.subinventory_code       =   xird_last.subinventory_code(+)
      AND     mmt.inventory_item_id       =   xird_last.inventory_item_id(+)
      AND     gd_f_max_practice_date      =   xird_last.practice_date(+)
      AND     mmt.organization_id         =   xird_today.organization_id(+)
      AND     mmt.subinventory_code       =   xird_today.subinventory_code(+)
      AND     mmt.inventory_item_id       =   xird_today.inventory_item_id(+)
      AND     gd_f_business_date          =   xird_today.practice_date(+)
      AND     mmt.transaction_type_id     =   mtt.transaction_type_id
      AND     mtt.attribute3       IS NOT NULL
      ORDER BY  msi1.attribute7
               ,mmt.subinventory_code
               ,mmt.inventory_item_id
               ,mmt.transaction_date  DESC;
    --
    -- ���ގ���f�[�^�擾���R�[�h�^
    material_transaction_rec    material_transaction_cur%ROWTYPE;
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
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    -- ===================================
    --  1.�݌ɉ�v����CLOSE�`�F�b�N
    -- ===================================
    xxcoi_common_pkg.org_acct_period_chk(
       in_organization_id   =>  gn_f_organization_id                  -- �g�DID
      ,id_target_date       =>  ADD_MONTHS(gd_f_business_date, -1)    -- �Ɩ��������t�̑O��
      ,ob_chk_result        =>  lb_chk_result                         -- �`�F�b�N����
      ,ov_errbuf            =>  lv_errbuf
      ,ov_retcode           =>  lv_retcode
      ,ov_errmsg            =>  lv_errmsg
    );
    -- �I������
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- ===================================
    --  �����f�[�^�쐬
    -- ===================================
    -- �J�[�\��OPEN
    OPEN  material_transaction_cur;
    FETCH material_transaction_cur  INTO  material_transaction_rec;
    --
    lt_base_code                :=  material_transaction_rec.base_code;
    lt_subinventory_code        :=  material_transaction_rec.subinventory_code;
    lt_inventory_item_id        :=  material_transaction_rec.inventory_item_id;
    lv_transaction_month        :=  material_transaction_rec.transaction_month;
    --
    <<set_material_loop>>
    LOOP
      -- ���ގ���f�[�^���P�����擾����Ȃ��ꍇ�ALOOP�����I��
      EXIT set_material_loop WHEN material_transaction_cur%NOTFOUND AND ln_material_flag = 0;
      --
      -- ���_�A�ۊǏꏊ�A�i�ځA������i�N���j�̂����ꂩ���O���R�[�h�ƈ�v���Ȃ��ꍇ�A�܂��́A
      -- �ŏI���R�[�h�̏���������̏ꍇ�A�����f�[�^��}���A�܂��́A�X�V
      IF (    (material_transaction_rec.base_code          <>  lt_base_code)
          OR  (material_transaction_rec.subinventory_code  <>  lt_subinventory_code)
          OR  (material_transaction_rec.inventory_item_id  <>  lt_inventory_item_id)
          OR  (material_transaction_rec.transaction_month  <>  lv_transaction_month)
          OR  (material_transaction_cur%NOTFOUND)
         )
      THEN
        --
        -- ===================================
        --  2.�W�������擾
        -- ===================================
        xxcoi_common_pkg.get_cmpnt_cost(
          in_item_id      =>  lt_inventory_item_id                            -- �i��ID
         ,in_org_id       =>  gn_f_organization_id                            -- �g�DID
         ,id_period_date  =>  lt_transaction_date                             -- �Ώۓ�
         ,ov_cmpnt_cost   =>  lt_standard_cost                                -- �W������
         ,ov_errbuf       =>  lv_errbuf                                       -- �G���[���b�Z�[�W
         ,ov_retcode      =>  lv_retcode                                      -- ���^�[���E�R�[�h
         ,ov_errmsg       =>  lv_errmsg                                       -- ���[�U�[�E�G���[���b�Z�[�W
        );
        -- �I���p�����[�^����
        IF (lv_retcode = cv_status_error) THEN
          lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application  => cv_short_name
                          ,iv_name         => cv_msg_xxcoi1_10285
                         );
          lv_errbuf   := lv_errmsg;
          RAISE global_api_expt;
        END IF;
        --
        -- ===================================
        --  2.�c�ƌ����擾
        -- ===================================
        xxcoi_common_pkg.get_discrete_cost(
          in_item_id        =>  lt_inventory_item_id                            -- �i��ID
         ,in_org_id         =>  gn_f_organization_id                            -- �g�DID
         ,id_target_date    =>  lt_transaction_date                             -- �Ώۓ�
         ,ov_discrete_cost  =>  lt_operation_cost                               -- �c�ƌ���
         ,ov_errbuf         =>  lv_errbuf                                       -- �G���[���b�Z�[�W
         ,ov_retcode        =>  lv_retcode                                      -- ���^�[���E�R�[�h
         ,ov_errmsg         =>  lv_errmsg                                       -- ���[�U�[�E�G���[���b�Z�[�W
        );
        -- �I���p�����[�^����
        IF (lv_retcode = cv_status_error) THEN
          lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application  => cv_short_name
                          ,iv_name         => cv_msg_xxcoi1_10293
                         );
          lv_errbuf   := lv_errmsg;
          RAISE global_api_expt;
        END IF;
        --
        -- ==========================
        --  �X�V�p�f�[�^�ݒ�
        -- ==========================
        lt_sales_shipped            :=  gt_quantity(1)  * -1  ;       -- ����o��
        lt_sales_shipped_b          :=  gt_quantity(2)        ;       -- ����o�ɐU��
        lt_return_goods             :=  gt_quantity(3)        ;       -- �ԕi
        lt_return_goods_b           :=  gt_quantity(4)  * -1  ;       -- �ԕi�U��
        lt_warehouse_ship           :=  gt_quantity(5)  * -1  ;       -- �q�ɂ֕Ԍ�
        lt_truck_ship               :=  gt_quantity(6)  * -1  ;       -- �c�ƎԂ֏o��
        lt_others_ship              :=  gt_quantity(7)  * -1  ;       -- ���o�ɁQ���̑��o��
        lt_warehouse_stock          :=  gt_quantity(8)        ;       -- �q�ɂ�����
        lt_truck_stock              :=  gt_quantity(9)        ;       -- �c�ƎԂ�����
        lt_others_stock             :=  gt_quantity(10)       ;       -- ���o�ɁQ���̑�����
        lt_change_stock             :=  gt_quantity(11)       ;       -- �q�֓���
        lt_change_ship              :=  gt_quantity(12) * -1  ;       -- �q�֏o��
        lt_goods_transfer_old       :=  gt_quantity(13) * -1  ;       -- ���i�U�ցi�����i�j
        lt_goods_transfer_new       :=  gt_quantity(14)       ;       -- ���i�U�ցi�V���i�j
        lt_sample_quantity          :=  gt_quantity(15) * -1  ;       -- ���{�o��
        lt_sample_quantity_b        :=  gt_quantity(16)       ;       -- ���{�o�ɐU��
        lt_customer_sample_ship     :=  gt_quantity(17) * -1  ;       -- �ڋq���{�o��
        lt_customer_sample_ship_b   :=  gt_quantity(18)       ;       -- �ڋq���{�o�ɐU��
        lt_customer_support_ss      :=  gt_quantity(19) * -1  ;       -- �ڋq���^���{�o��
        lt_customer_support_ss_b    :=  gt_quantity(20)       ;       -- �ڋq���^���{�o�ɐU��
        lt_vd_supplement_stock      :=  gt_quantity(21)       ;       -- ����VD��[����
        lt_vd_supplement_ship       :=  gt_quantity(22) * -1  ;       -- ����VD��[�o��
        lt_inventory_change_in      :=  gt_quantity(23)       ;       -- ��݌ɕύX����
        lt_inventory_change_out     :=  gt_quantity(24) * -1  ;       -- ��݌ɕύX�o��
        lt_factory_return           :=  gt_quantity(25) * -1  ;       -- �H��ԕi
        lt_factory_return_b         :=  gt_quantity(26)       ;       -- �H��ԕi�U��
        lt_factory_change           :=  gt_quantity(27) * -1  ;       -- �H��q��
        lt_factory_change_b         :=  gt_quantity(28)       ;       -- �H��q�֐U��
        lt_removed_goods            :=  gt_quantity(29) * -1  ;       -- �p�p
        lt_removed_goods_b          :=  gt_quantity(30)       ;       -- �p�p�U��
        lt_factory_stock            :=  gt_quantity(31)       ;       -- �H�����
        lt_factory_stock_b          :=  gt_quantity(32) * -1  ;       -- �H����ɐU��
        lt_ccm_sample_ship          :=  gt_quantity(33) * -1  ;       -- �ڋq�L����`��A���Џ��i
        lt_ccm_sample_ship_b        :=  gt_quantity(34)       ;       -- �ڋq�L����`��A���Џ��i�U��
        lt_wear_decrease            :=  gt_quantity(35)       ;       -- �I�����Ց�
        lt_wear_increase            :=  gt_quantity(36) * -1  ;       -- �I�����Ռ�
        lt_selfbase_ship            :=  gt_quantity(37) * -1  ;       -- �ۊǏꏊ�ړ��Q�����_�o��
        lt_selfbase_stock           :=  gt_quantity(38)       ;       -- �ۊǏꏊ�ړ��Q�����_����
        -- ����݌ɐ�
        lt_book_inventory_quantity  :=  gt_quantity(1)  + gt_quantity(2)  + gt_quantity(3)
                                      + gt_quantity(4)  + gt_quantity(5)  + gt_quantity(6)
                                      + gt_quantity(7)  + gt_quantity(8)  + gt_quantity(9)
                                      + gt_quantity(10) + gt_quantity(11) + gt_quantity(12)
                                      + gt_quantity(13) + gt_quantity(14) + gt_quantity(15)
                                      + gt_quantity(16) + gt_quantity(17) + gt_quantity(18)
                                      + gt_quantity(19) + gt_quantity(20) + gt_quantity(21)
                                      + gt_quantity(22) + gt_quantity(23) + gt_quantity(24)
                                      + gt_quantity(25) + gt_quantity(26) + gt_quantity(27)
                                      + gt_quantity(28) + gt_quantity(29) + gt_quantity(30)
                                      + gt_quantity(31) + gt_quantity(32) + gt_quantity(33)
                                      + gt_quantity(34) + gt_quantity(35) + gt_quantity(36)
                                      + gt_quantity(37) + gt_quantity(38);
        --
        IF (    (lt_sales_shipped            = 0)   -- ����o��
            AND (lt_sales_shipped_b          = 0)   -- ����o�ɐU��
            AND (lt_return_goods             = 0)   -- �ԕi
            AND (lt_return_goods_b           = 0)   -- �ԕi�U��
            AND (lt_warehouse_ship           = 0)   -- �q�ɂ֕Ԍ�
            AND (lt_truck_ship               = 0)   -- �c�ƎԂ֏o��
            AND (lt_others_ship              = 0)   -- ���o�ɁQ���̑��o��
            AND (lt_warehouse_stock          = 0)   -- �q�ɂ�����
            AND (lt_truck_stock              = 0)   -- �c�ƎԂ�����
            AND (lt_others_stock             = 0)   -- ���o�ɁQ���̑�����
            AND (lt_change_stock             = 0)   -- �q�֓���
            AND (lt_change_ship              = 0)   -- �q�֏o��
            AND (lt_goods_transfer_old       = 0)   -- ���i�U�ցi�����i�j
            AND (lt_goods_transfer_new       = 0)   -- ���i�U�ցi�V���i�j
            AND (lt_sample_quantity          = 0)   -- ���{�o��
            AND (lt_sample_quantity_b        = 0)   -- ���{�o�ɐU��
            AND (lt_customer_sample_ship     = 0)   -- �ڋq���{�o��
            AND (lt_customer_sample_ship_b   = 0)   -- �ڋq���{�o�ɐU��
            AND (lt_customer_support_ss      = 0)   -- �ڋq���^���{�o��
            AND (lt_customer_support_ss_b    = 0)   -- �ڋq���^���{�o�ɐU��
            AND (lt_vd_supplement_stock      = 0)   -- ����VD��[����
            AND (lt_vd_supplement_ship       = 0)   -- ����VD��[�o��
            AND (lt_inventory_change_in      = 0)   -- ��݌ɕύX����
            AND (lt_inventory_change_out     = 0)   -- ��݌ɕύX�o��
            AND (lt_factory_return           = 0)   -- �H��ԕi
            AND (lt_factory_return_b         = 0)   -- �H��ԕi�U��
            AND (lt_factory_change           = 0)   -- �H��q��
            AND (lt_factory_change_b         = 0)   -- �H��q�֐U��
            AND (lt_removed_goods            = 0)   -- �p�p
            AND (lt_removed_goods_b          = 0)   -- �p�p�U��
            AND (lt_factory_stock            = 0)   -- �H�����
            AND (lt_factory_stock_b          = 0)   -- �H����ɐU��
            AND (lt_ccm_sample_ship          = 0)   -- �ڋq�L����`��A���Џ��i
            AND (lt_ccm_sample_ship_b        = 0)   -- �ڋq�L����`��A���Џ��i�U��
            AND (lt_wear_decrease            = 0)   -- �I�����Ց�
            AND (lt_wear_increase            = 0)   -- �I�����Ռ�
            AND (lt_selfbase_ship            = 0)   -- �ۊǏꏊ�ړ��Q�����_�o��
            AND (lt_selfbase_stock           = 0)   -- �ۊǏꏊ�ړ��Q�����_����
            AND (lt_book_inventory_quantity  = 0)   -- ����݌ɐ�
           )
        THEN
          -- �S���ڂO�̏ꍇ�A�����݌Ɏ󕥕\���쐬���Ȃ�
-- == 2009/08/26 V1.8 Modified START ===============================================================
---- == 2009/06/05 V1.6 Added START ===============================================================
--          -- �݌v�e�[�u���쐬�p�N����ݒ�
--          lt_practice_date  :=  NULL;
---- == 2009/06/05 V1.6 Added START ===============================================================
          -- �������Ȃ�
          NULL;
-- == 2009/08/26 V1.8 Modified END   ===============================================================
          --
        ELSIF (lv_transaction_month = TO_CHAR(gd_f_business_date, cv_month)) THEN
          -- ��������Ɩ��N���Ɠ���̏ꍇ�A�����f�[�^�Ƃ��ď���
          -- ==========================
          --  �����f�[�^�쐬�i�������j
          -- ==========================
          -- �������iINSERT�j
          ln_today_data         :=  ln_today_data + 1;        -- ���ގ���������f�[�^�����J�E���g
          --
          IF (lt_today_book_inv_quantity IS NOT NULL) THEN
            -- �������f�[�^�����݂���ꍇ�A��������UPDATE
            UPDATE  xxcoi_inv_reception_daily
            SET     sales_shipped               = sales_shipped           + lt_sales_shipped            -- 10.����o��
                   ,sales_shipped_b             = sales_shipped_b         + lt_sales_shipped_b          -- 11.����o�ɐU��
                   ,return_goods                = return_goods            + lt_return_goods             -- 12.�ԕi
                   ,return_goods_b              = return_goods_b          + lt_return_goods_b           -- 13.�ԕi�U��
                   ,warehouse_ship              = warehouse_ship          + lt_warehouse_ship           -- 14.�q�ɂ֕Ԍ�
                   ,truck_ship                  = truck_ship              + lt_truck_ship               -- 15.�c�ƎԂ֏o��
                   ,others_ship                 = others_ship             + lt_others_ship              -- 16.���o�ɁQ���̑��o��
                   ,warehouse_stock             = warehouse_stock         + lt_warehouse_stock          -- 17.�q�ɂ�����
                   ,truck_stock                 = truck_stock             + lt_truck_stock              -- 18.�c�ƎԂ�����
                   ,others_stock                = others_stock            + lt_others_stock             -- 19.���o�ɁQ���̑�����
                   ,change_stock                = change_stock            + lt_change_stock             -- 20.�q�֓���
                   ,change_ship                 = change_ship             + lt_change_ship              -- 21.�q�֏o��
                   ,goods_transfer_old          = goods_transfer_old      + lt_goods_transfer_old       -- 22.���i�U�ցi�����i�j
                   ,goods_transfer_new          = goods_transfer_new      + lt_goods_transfer_new       -- 23.���i�U�ցi�V���i�j
                   ,sample_quantity             = sample_quantity         + lt_sample_quantity          -- 24.���{�o��
                   ,sample_quantity_b           = sample_quantity_b       + lt_sample_quantity_b        -- 25.���{�o�ɐU��
                   ,customer_sample_ship        = customer_sample_ship    + lt_customer_sample_ship     -- 26.�ڋq���{�o��
                   ,customer_sample_ship_b      = customer_sample_ship_b  + lt_customer_sample_ship_b   -- 27.�ڋq���{�o�ɐU��
                   ,customer_support_ss         = customer_support_ss     + lt_customer_support_ss      -- 28.�ڋq���^���{�o��
                   ,customer_support_ss_b       = customer_support_ss_b   + lt_customer_support_ss_b    -- 29.�ڋq���^���{�o�ɐU��
                   ,vd_supplement_stock         = vd_supplement_stock     + lt_vd_supplement_stock      -- 32.����VD��[����
                   ,vd_supplement_ship          = vd_supplement_ship      + lt_vd_supplement_ship       -- 33.����VD��[�o��
                   ,inventory_change_in         = inventory_change_in     + lt_inventory_change_in      -- 34.��݌ɕύX����
                   ,inventory_change_out        = inventory_change_out    + lt_inventory_change_out     -- 35.��݌ɕύX�o��
                   ,factory_return              = factory_return          + lt_factory_return           -- 36.�H��ԕi
                   ,factory_return_b            = factory_return_b        + lt_factory_return_b         -- 37.�H��ԕi�U��
                   ,factory_change              = factory_change          + lt_factory_change           -- 38.�H��q��
                   ,factory_change_b            = factory_change_b        + lt_factory_change_b         -- 39.�H��q�֐U��
                   ,removed_goods               = removed_goods           + lt_removed_goods            -- 40.�p�p
                   ,removed_goods_b             = removed_goods_b         + lt_removed_goods_b          -- 41.�p�p�U��
                   ,factory_stock               = factory_stock           + lt_factory_stock            -- 42.�H�����
                   ,factory_stock_b             = factory_stock_b         + lt_factory_stock_b          -- 43.�H����ɐU��
                   ,ccm_sample_ship             = ccm_sample_ship         + lt_ccm_sample_ship          -- 30.�ڋq�L����`��A���Џ��i
                   ,ccm_sample_ship_b           = ccm_sample_ship_b       + lt_ccm_sample_ship_b        -- 31.�ڋq�L����`��A���Џ��i�U��
                   ,wear_decrease               = wear_decrease           + lt_wear_decrease            -- 44.�I�����Ց�
                   ,wear_increase               = wear_increase           + lt_wear_increase            -- 45.�I�����Ռ�
                   ,selfbase_ship               = selfbase_ship           + lt_selfbase_ship            -- 46.�ۊǏꏊ�ړ��Q�����_�o��
                   ,selfbase_stock              = selfbase_stock          + lt_selfbase_stock           -- 47.�ۊǏꏊ�ړ��Q�����_����
                   ,book_inventory_quantity     = book_inventory_quantity + lt_book_inventory_quantity  -- 48.����݌�
                   ,last_update_date            = SYSDATE                                               -- 49.�ŏI�X�V��
                   ,last_updated_by             = cn_last_updated_by                                    -- 50.�ŏI�X�V��
                   ,last_update_login           = cn_last_update_login                                  -- 53.�ŏI�X�V���[�U
                   ,request_id                  = cn_request_id                                         -- 54.�v��ID
                   ,program_application_id      = cn_program_application_id                             -- 55.�v���O�����A�v���P�[�V����ID
                   ,program_id                  = cn_program_id                                         -- 56.�v���O����ID
                   ,program_update_date         = SYSDATE                                               -- 57.�v���O�����X�V��
            WHERE   base_code           =   lt_base_code
---- == 2009/08/26 V1.8 Added START ===============================================================
            AND     organization_id     =   gn_f_organization_id
---- == 2009/08/26 V1.8 Added END   ===============================================================
            AND     subinventory_code   =   lt_subinventory_code
            AND     inventory_item_id   =   lt_inventory_item_id
            AND     practice_date       =   gd_f_business_date;
            --
          ELSE
            -- �������f�[�^�����݂��Ȃ��ꍇ�A��������INSERT
            INSERT INTO xxcoi_inv_reception_daily(
              base_code                             -- 01.���_�R�[�h
             ,organization_id                       -- 02.�g�DID
             ,subinventory_code                     -- 03.�ۊǏꏊ
             ,practice_date                         -- 04.�N����
             ,inventory_item_id                     -- 05.�i��ID
             ,subinventory_type                     -- 06.�ۊǏꏊ�敪
             ,operation_cost                        -- 07.�c�ƌ���
             ,standard_cost                         -- 08.�W������
             ,previous_inventory_quantity           -- 09.�O���݌ɐ�
             ,sales_shipped                         -- 10.����o��
             ,sales_shipped_b                       -- 11.����o�ɐU��
             ,return_goods                          -- 12.�ԕi
             ,return_goods_b                        -- 13.�ԕi�U��
             ,warehouse_ship                        -- 14.�q�ɂ֕Ԍ�
             ,truck_ship                            -- 15.�c�ƎԂ֏o��
             ,others_ship                           -- 16.���o�ɁQ���̑��o��
             ,warehouse_stock                       -- 17.�q�ɂ�����
             ,truck_stock                           -- 18.�c�ƎԂ�����
             ,others_stock                          -- 19.���o�ɁQ���̑�����
             ,change_stock                          -- 20.�q�֓���
             ,change_ship                           -- 21.�q�֏o��
             ,goods_transfer_old                    -- 22.���i�U�ցi�����i�j
             ,goods_transfer_new                    -- 23.���i�U�ցi�V���i�j
             ,sample_quantity                       -- 24.���{�o��
             ,sample_quantity_b                     -- 25.���{�o�ɐU��
             ,customer_sample_ship                  -- 26.�ڋq���{�o��
             ,customer_sample_ship_b                -- 27.�ڋq���{�o�ɐU��
             ,customer_support_ss                   -- 28.�ڋq���^���{�o��
             ,customer_support_ss_b                 -- 29.�ڋq���^���{�o�ɐU��
             ,vd_supplement_stock                   -- 32.����VD��[����
             ,vd_supplement_ship                    -- 33.����VD��[�o��
             ,inventory_change_in                   -- 34.��݌ɕύX����
             ,inventory_change_out                  -- 35.��݌ɕύX�o��
             ,factory_return                        -- 36.�H��ԕi
             ,factory_return_b                      -- 37.�H��ԕi�U��
             ,factory_change                        -- 38.�H��q��
             ,factory_change_b                      -- 39.�H��q�֐U��
             ,removed_goods                         -- 40.�p�p
             ,removed_goods_b                       -- 41.�p�p�U��
             ,factory_stock                         -- 42.�H�����
             ,factory_stock_b                       -- 43.�H����ɐU��
             ,ccm_sample_ship                       -- 30.�ڋq�L����`��A���Џ��i
             ,ccm_sample_ship_b                     -- 31.�ڋq�L����`��A���Џ��i�U��
             ,wear_decrease                         -- 44.�I�����Ց�
             ,wear_increase                         -- 45.�I�����Ռ�
             ,selfbase_ship                         -- 46.�ۊǏꏊ�ړ��Q�����_�o��
             ,selfbase_stock                        -- 47.�ۊǏꏊ�ړ��Q�����_����
             ,book_inventory_quantity               -- 48.����݌ɐ�
             ,last_update_date                      -- 49.�ŏI�X�V��
             ,last_updated_by                       -- 50.�ŏI�X�V��
             ,creation_date                         -- 51.�쐬��
             ,created_by                            -- 52.�쐬��
             ,last_update_login                     -- 53.�ŏI�X�V���[�U
             ,request_id                            -- 54.�v��ID
             ,program_application_id                -- 55.�v���O�����A�v���P�[�V����ID
             ,program_id                            -- 56.�v���O����ID
             ,program_update_date                   -- 57.�v���O�����X�V��
            )VALUES(
              lt_base_code                          -- 01
             ,gn_f_organization_id                  -- 02
             ,lt_subinventory_code                  -- 03
             ,gd_f_business_date                    -- 04
             ,lt_inventory_item_id                  -- 05
             ,lt_subinventory_type                  -- 06
             ,lt_operation_cost                     -- 07
             ,lt_standard_cost                      -- 08
             ,0                                     -- 09
             ,lt_sales_shipped                      -- 10
             ,lt_sales_shipped_b                    -- 11
             ,lt_return_goods                       -- 12
             ,lt_return_goods_b                     -- 13
             ,lt_warehouse_ship                     -- 14
             ,lt_truck_ship                         -- 15
             ,lt_others_ship                        -- 16
             ,lt_warehouse_stock                    -- 17
             ,lt_truck_stock                        -- 18
             ,lt_others_stock                       -- 19
             ,lt_change_stock                       -- 20
             ,lt_change_ship                        -- 21
             ,lt_goods_transfer_old                 -- 22
             ,lt_goods_transfer_new                 -- 23
             ,lt_sample_quantity                    -- 24
             ,lt_sample_quantity_b                  -- 25
             ,lt_customer_sample_ship               -- 26
             ,lt_customer_sample_ship_b             -- 27
             ,lt_customer_support_ss                -- 28
             ,lt_customer_support_ss_b              -- 29
             ,lt_vd_supplement_stock                -- 32
             ,lt_vd_supplement_ship                 -- 33
             ,lt_inventory_change_in                -- 34
             ,lt_inventory_change_out               -- 35
             ,lt_factory_return                     -- 36
             ,lt_factory_return_b                   -- 37
             ,lt_factory_change                     -- 38
             ,lt_factory_change_b                   -- 39
             ,lt_removed_goods                      -- 40
             ,lt_removed_goods_b                    -- 41
             ,lt_factory_stock                      -- 42
             ,lt_factory_stock_b                    -- 43
             ,lt_ccm_sample_ship                    -- 30
             ,lt_ccm_sample_ship_b                  -- 31
             ,lt_wear_decrease                      -- 44
             ,lt_wear_increase                      -- 45
             ,lt_selfbase_ship                      -- 46
             ,lt_selfbase_stock                     -- 47
             ,lt_book_inventory_quantity            -- 48
             ,SYSDATE                               -- 49
             ,cn_last_updated_by                    -- 50
             ,SYSDATE                               -- 51
             ,cn_created_by                         -- 52
             ,cn_last_update_login                  -- 53
             ,cn_request_id                         -- 54
             ,cn_program_application_id             -- 55
             ,cn_program_id                         -- 56
             ,SYSDATE                               -- 57
            );
            --
---- == 2009/08/26 V1.8 Added START ===============================================================
            gn_target_cnt := gn_target_cnt + 1;
---- == 2009/08/26 V1.8 Added END   ===============================================================
          END IF;
          --
-- == 2009/08/26 V1.8 Deleted START ===============================================================
---- == 2009/05/28 V1.4 Added START ===============================================================
--          -- �݌v�e�[�u���쐬�p�N����ݒ�
--          lt_practice_date  :=  gd_f_business_date;
---- == 2009/05/28 V1.4 Added START ===============================================================
-- == 2009/08/26 V1.8 Deleted END   ===============================================================
        ELSE
          -- ========================================
          --  �����f�[�^�쐬�i�O�����j
          -- ========================================
          -- ��������Ɩ��N���ƕs��v�̏ꍇ�A�O���f�[�^�Ƃ��ď���
          -- �݌ɉ�v���Ԃ�OPEN
          IF (lb_chk_result) THEN
            IF (lt_last_book_inv_quantity IS NOT NULL) THEN
              -- ���b�N���������s
              BEGIN
                SELECT  1
                INTO    ln_dummy
                FROM    xxcoi_inv_reception_daily   xird
                WHERE   xird.base_code           =   lt_base_code
---- == 2009/08/26 V1.8 Added START ===============================================================
                AND     xird.organization_id     =   gn_f_organization_id
---- == 2009/08/26 V1.8 Added END   ===============================================================
                AND     xird.subinventory_code   =   lt_subinventory_code
                AND     xird.inventory_item_id   =   lt_inventory_item_id
                AND     xird.practice_date       =   gd_f_max_practice_date
                FOR UPDATE NOWAIT;
                --
              EXCEPTION
                WHEN  lock_error_expt THEN
                  lv_errmsg   := xxccp_common_pkg.get_msg(
                                   iv_application  => cv_short_name
                                  ,iv_name         => cv_msg_xxcoi1_10363
                                 );
                  lv_errbuf   := lv_errmsg;
                  RAISE global_process_expt;
                  --
              END;
              --
              -- �O���f�[�^�����݂���ꍇ�A�O������UPDATE
              UPDATE  xxcoi_inv_reception_daily
              SET     sales_shipped             = sales_shipped           + lt_sales_shipped            -- 10.����o��
                     ,sales_shipped_b           = sales_shipped_b         + lt_sales_shipped_b          -- 11.����o�ɐU��
                     ,return_goods              = return_goods            + lt_return_goods             -- 12.�ԕi
                     ,return_goods_b            = return_goods_b          + lt_return_goods_b           -- 13.�ԕi�U��
                     ,warehouse_ship            = warehouse_ship          + lt_warehouse_ship           -- 14.�q�ɂ֕Ԍ�
                     ,truck_ship                = truck_ship              + lt_truck_ship               -- 15.�c�ƎԂ֏o��
                     ,others_ship               = others_ship             + lt_others_ship              -- 16.���o�ɁQ���̑��o��
                     ,warehouse_stock           = warehouse_stock         + lt_warehouse_stock          -- 17.�q�ɂ�����
                     ,truck_stock               = truck_stock             + lt_truck_stock              -- 18.�c�ƎԂ�����
                     ,others_stock              = others_stock            + lt_others_stock             -- 19.���o�ɁQ���̑�����
                     ,change_stock              = change_stock            + lt_change_stock             -- 20.�q�֓���
                     ,change_ship               = change_ship             + lt_change_ship              -- 21.�q�֏o��
                     ,goods_transfer_old        = goods_transfer_old      + lt_goods_transfer_old       -- 22.���i�U�ցi�����i�j
                     ,goods_transfer_new        = goods_transfer_new      + lt_goods_transfer_new       -- 23.���i�U�ցi�V���i�j
                     ,sample_quantity           = sample_quantity         + lt_sample_quantity          -- 24.���{�o��
                     ,sample_quantity_b         = sample_quantity_b       + lt_sample_quantity_b        -- 25.���{�o�ɐU��
                     ,customer_sample_ship      = customer_sample_ship    + lt_customer_sample_ship     -- 26.�ڋq���{�o��
                     ,customer_sample_ship_b    = customer_sample_ship_b  + lt_customer_sample_ship_b   -- 27.�ڋq���{�o�ɐU��
                     ,customer_support_ss       = customer_support_ss     + lt_customer_support_ss      -- 28.�ڋq���^���{�o��
                     ,customer_support_ss_b     = customer_support_ss_b   + lt_customer_support_ss_b    -- 29.�ڋq���^���{�o�ɐU��
                     ,vd_supplement_stock       = vd_supplement_stock     + lt_vd_supplement_stock      -- 32.����VD��[����
                     ,vd_supplement_ship        = vd_supplement_ship      + lt_vd_supplement_ship       -- 33.����VD��[�o��
                     ,inventory_change_in       = inventory_change_in     + lt_inventory_change_in      -- 34.��݌ɕύX����
                     ,inventory_change_out      = inventory_change_out    + lt_inventory_change_out     -- 35.��݌ɕύX�o��
                     ,factory_return            = factory_return          + lt_factory_return           -- 36.�H��ԕi
                     ,factory_return_b          = factory_return_b        + lt_factory_return_b         -- 37.�H��ԕi�U��
                     ,factory_change            = factory_change          + lt_factory_change           -- 38.�H��q��
                     ,factory_change_b          = factory_change_b        + lt_factory_change_b         -- 39.�H��q�֐U��
                     ,removed_goods             = removed_goods           + lt_removed_goods            -- 40.�p�p
                     ,removed_goods_b           = removed_goods_b         + lt_removed_goods_b          -- 41.�p�p�U��
                     ,factory_stock             = factory_stock           + lt_factory_stock            -- 42.�H�����
                     ,factory_stock_b           = factory_stock_b         + lt_factory_stock_b          -- 43.�H����ɐU��
                     ,ccm_sample_ship           = ccm_sample_ship         + lt_ccm_sample_ship          -- 30.�ڋq�L����`��A���Џ��i
                     ,ccm_sample_ship_b         = ccm_sample_ship_b       + lt_ccm_sample_ship_b        -- 31.�ڋq�L����`��A���Џ��i�U��
                     ,wear_decrease             = wear_decrease           + lt_wear_decrease            -- 44.�I�����Ց�
                     ,wear_increase             = wear_increase           + lt_wear_increase            -- 45.�I�����Ռ�
                     ,selfbase_ship             = selfbase_ship           + lt_selfbase_ship            -- 46.�ۊǏꏊ�ړ��Q�����_�o��
                     ,selfbase_stock            = selfbase_stock          + lt_selfbase_stock           -- 47.�ۊǏꏊ�ړ��Q�����_����
                     ,book_inventory_quantity   = book_inventory_quantity + lt_book_inventory_quantity  -- 48.����݌�
                     ,last_update_date          = SYSDATE                                               -- 49.�ŏI�X�V��
                     ,last_updated_by           = cn_last_updated_by                                    -- 50.�ŏI�X�V��
                     ,last_update_login         = cn_last_update_login                                  -- 53.�ŏI�X�V���[�U
                     ,request_id                = cn_request_id                                         -- 54.�v��ID
                     ,program_application_id    = cn_program_application_id                             -- 55.�v���O�����A�v���P�[�V����ID
                     ,program_id                = cn_program_id                                         -- 56.�v���O����ID
                     ,program_update_date       = SYSDATE                                               -- 57.�v���O�����X�V��
              WHERE   base_code           =   lt_base_code
---- == 2009/08/26 V1.8 Added START ===============================================================
              AND     organization_id     =   gn_f_organization_id
---- == 2009/08/26 V1.8 Added END   ===============================================================
              AND     subinventory_code   =   lt_subinventory_code
              AND     inventory_item_id   =   lt_inventory_item_id
              AND     practice_date       =   gd_f_max_practice_date;
              --
---- == 2009/08/26 V1.8 Added START ===============================================================
              gn_target_cnt := gn_target_cnt + 1;
---- == 2009/08/26 V1.8 Added END   ===============================================================
            ELSE
              -- �O���f�[�^�����݂��Ȃ��ꍇ�A�O������INSERT
              INSERT INTO xxcoi_inv_reception_daily(
                base_code                             -- 01.���_�R�[�h
               ,organization_id                       -- 02.�g�DID
               ,subinventory_code                     -- 03.�ۊǏꏊ
               ,practice_date                         -- 04.�N����
               ,inventory_item_id                     -- 05.�i��ID
               ,subinventory_type                     -- 06.�ۊǏꏊ�敪
               ,operation_cost                        -- 07.�c�ƌ���
               ,standard_cost                         -- 08.�W������
               ,previous_inventory_quantity           -- 09.�O���݌ɐ�
               ,sales_shipped                         -- 10.����o��
               ,sales_shipped_b                       -- 11.����o�ɐU��
               ,return_goods                          -- 12.�ԕi
               ,return_goods_b                        -- 13.�ԕi�U��
               ,warehouse_ship                        -- 14.�q�ɂ֕Ԍ�
               ,truck_ship                            -- 15.�c�ƎԂ֏o��
               ,others_ship                           -- 16.���o�ɁQ���̑��o��
               ,warehouse_stock                       -- 17.�q�ɂ�����
               ,truck_stock                           -- 18.�c�ƎԂ�����
               ,others_stock                          -- 19.���o�ɁQ���̑�����
               ,change_stock                          -- 20.�q�֓���
               ,change_ship                           -- 21.�q�֏o��
               ,goods_transfer_old                    -- 22.���i�U�ցi�����i�j
               ,goods_transfer_new                    -- 23.���i�U�ցi�V���i�j
               ,sample_quantity                       -- 24.���{�o��
               ,sample_quantity_b                     -- 25.���{�o�ɐU��
               ,customer_sample_ship                  -- 26.�ڋq���{�o��
               ,customer_sample_ship_b                -- 27.�ڋq���{�o�ɐU��
               ,customer_support_ss                   -- 28.�ڋq���^���{�o��
               ,customer_support_ss_b                 -- 29.�ڋq���^���{�o�ɐU��
               ,vd_supplement_stock                   -- 32.����VD��[����
               ,vd_supplement_ship                    -- 33.����VD��[�o��
               ,inventory_change_in                   -- 34.��݌ɕύX����
               ,inventory_change_out                  -- 35.��݌ɕύX�o��
               ,factory_return                        -- 36.�H��ԕi
               ,factory_return_b                      -- 37.�H��ԕi�U��
               ,factory_change                        -- 38.�H��q��
               ,factory_change_b                      -- 39.�H��q�֐U��
               ,removed_goods                         -- 40.�p�p
               ,removed_goods_b                       -- 41.�p�p�U��
               ,factory_stock                         -- 42.�H�����
               ,factory_stock_b                       -- 43.�H����ɐU��
               ,ccm_sample_ship                       -- 30.�ڋq�L����`��A���Џ��i
               ,ccm_sample_ship_b                     -- 31.�ڋq�L����`��A���Џ��i�U��
               ,wear_decrease                         -- 44.�I�����Ց�
               ,wear_increase                         -- 45.�I�����Ռ�
               ,selfbase_ship                         -- 46.�ۊǏꏊ�ړ��Q�����_�o��
               ,selfbase_stock                        -- 47.�ۊǏꏊ�ړ��Q�����_����
               ,book_inventory_quantity               -- 48.����݌ɐ�
               ,last_update_date                      -- 49.�ŏI�X�V��
               ,last_updated_by                       -- 50.�ŏI�X�V��
               ,creation_date                         -- 51.�쐬��
               ,created_by                            -- 52.�쐬��
               ,last_update_login                     -- 53.�ŏI�X�V���[�U
               ,request_id                            -- 54.�v��ID
               ,program_application_id                -- 55.�v���O�����A�v���P�[�V����ID
               ,program_id                            -- 56.�v���O����ID
               ,program_update_date                   -- 57.�v���O�����X�V��
              )VALUES(
                lt_base_code                          -- 01
               ,gn_f_organization_id                  -- 02
               ,lt_subinventory_code                  -- 03
               ,gd_f_max_practice_date                -- 04
               ,lt_inventory_item_id                  -- 05
               ,lt_subinventory_type                  -- 06
               ,lt_operation_cost                     -- 07
               ,lt_standard_cost                      -- 08
               ,0                                     -- 09
               ,lt_sales_shipped                      -- 10
               ,lt_sales_shipped_b                    -- 11
               ,lt_return_goods                       -- 12
               ,lt_return_goods_b                     -- 13
               ,lt_warehouse_ship                     -- 14
               ,lt_truck_ship                         -- 15
               ,lt_others_ship                        -- 16
               ,lt_warehouse_stock                    -- 17
               ,lt_truck_stock                        -- 18
               ,lt_others_stock                       -- 19
               ,lt_change_stock                       -- 20
               ,lt_change_ship                        -- 21
               ,lt_goods_transfer_old                 -- 22
               ,lt_goods_transfer_new                 -- 23
               ,lt_sample_quantity                    -- 24
               ,lt_sample_quantity_b                  -- 25
               ,lt_customer_sample_ship               -- 26
               ,lt_customer_sample_ship_b             -- 27
               ,lt_customer_support_ss                -- 28
               ,lt_customer_support_ss_b              -- 29
               ,lt_vd_supplement_stock                -- 32
               ,lt_vd_supplement_ship                 -- 33
               ,lt_inventory_change_in                -- 34
               ,lt_inventory_change_out               -- 35
               ,lt_factory_return                     -- 36
               ,lt_factory_return_b                   -- 37
               ,lt_factory_change                     -- 38
               ,lt_factory_change_b                   -- 39
               ,lt_removed_goods                      -- 40
               ,lt_removed_goods_b                    -- 41
               ,lt_factory_stock                      -- 42
               ,lt_factory_stock_b                    -- 43
               ,lt_ccm_sample_ship                    -- 30
               ,lt_ccm_sample_ship_b                  -- 31
               ,lt_wear_decrease                      -- 44
               ,lt_wear_increase                      -- 45
               ,lt_selfbase_ship                      -- 46
               ,lt_selfbase_stock                     -- 47
               ,lt_book_inventory_quantity            -- 48
               ,SYSDATE                               -- 49
               ,cn_last_updated_by                    -- 50
               ,SYSDATE                               -- 51
               ,cn_created_by                         -- 52
               ,cn_last_update_login                  -- 53
               ,cn_request_id                         -- 54
               ,cn_program_application_id             -- 55
               ,cn_program_id                         -- 56
               ,SYSDATE                               -- 57
              );
              --
---- == 2009/08/26 V1.8 Added START ===============================================================
              gn_target_cnt := gn_target_cnt + 1;
---- == 2009/08/26 V1.8 Added END   ===============================================================
            END IF;
            --
          END IF;
          --
          -- ========================================
          --  �����f�[�^�쐬�i�O�����𓖓����ɔ��f�j
          -- ========================================
          BEGIN
            -- �������R�[�h�̑��݃`�F�b�N
            SELECT  1
            INTO    ln_dummy
            FROM    xxcoi_inv_reception_daily   xird
            WHERE   xird.base_code           =   lt_base_code
---- == 2009/08/26 V1.8 Added START ===============================================================
            AND     xird.organization_id     =   gn_f_organization_id
---- == 2009/08/26 V1.8 Added END   ===============================================================
            AND     xird.subinventory_code   =   lt_subinventory_code
            AND     xird.inventory_item_id   =   lt_inventory_item_id
            AND     xird.practice_date       =   gd_f_business_date
            AND     ROWNUM = 1;
            --
            -- �����f�[�^�����݂���ꍇ�A��������UPDATE
            UPDATE  xxcoi_inv_reception_daily
            SET     previous_inventory_quantity = previous_inventory_quantity + lt_book_inventory_quantity  -- 09.�O���݌ɐ�
                   ,book_inventory_quantity     = book_inventory_quantity     + lt_book_inventory_quantity  -- 48.����݌�
                   ,last_update_date            = SYSDATE                                                   -- 49.�ŏI�X�V��
                   ,last_updated_by             = cn_last_updated_by                                        -- 50.�ŏI�X�V��
                   ,last_update_login           = cn_last_update_login                                      -- 53.�ŏI�X�V���[�U
                   ,request_id                  = cn_request_id                                             -- 54.�v��ID
                   ,program_application_id      = cn_program_application_id                                 -- 55.�v���O�����A�v���P�[�V����ID
                   ,program_id                  = cn_program_id                                             -- 56.�v���O����ID
                   ,program_update_date         = SYSDATE                                                   -- 57.�v���O�����X�V��
            WHERE   base_code           =   lt_base_code
---- == 2009/08/26 V1.8 Added START ===============================================================
            AND     organization_id     =   gn_f_organization_id
---- == 2009/08/26 V1.8 Added END   ===============================================================
            AND     subinventory_code   =   lt_subinventory_code
            AND     inventory_item_id   =   lt_inventory_item_id
            AND     practice_date       =   gd_f_business_date;
            --
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- �����f�[�^�����݂��Ȃ��ꍇ�A��������INSERT
              INSERT INTO xxcoi_inv_reception_daily(
                base_code                             -- 01.���_�R�[�h
               ,organization_id                       -- 02.�g�DID
               ,subinventory_code                     -- 03.�ۊǏꏊ
               ,practice_date                         -- 04.�N����
               ,inventory_item_id                     -- 05.�i��ID
               ,subinventory_type                     -- 06.�ۊǏꏊ�敪
               ,operation_cost                        -- 07.�c�ƌ���
               ,standard_cost                         -- 08.�W������
               ,previous_inventory_quantity           -- 09.�O���݌ɐ�
               ,sales_shipped                         -- 10.����o��
               ,sales_shipped_b                       -- 11.����o�ɐU��
               ,return_goods                          -- 12.�ԕi
               ,return_goods_b                        -- 13.�ԕi�U��
               ,warehouse_ship                        -- 14.�q�ɂ֕Ԍ�
               ,truck_ship                            -- 15.�c�ƎԂ֏o��
               ,others_ship                           -- 16.���o�ɁQ���̑��o��
               ,warehouse_stock                       -- 17.�q�ɂ�����
               ,truck_stock                           -- 18.�c�ƎԂ�����
               ,others_stock                          -- 19.���o�ɁQ���̑�����
               ,change_stock                          -- 20.�q�֓���
               ,change_ship                           -- 21.�q�֏o��
               ,goods_transfer_old                    -- 22.���i�U�ցi�����i�j
               ,goods_transfer_new                    -- 23.���i�U�ցi�V���i�j
               ,sample_quantity                       -- 24.���{�o��
               ,sample_quantity_b                     -- 25.���{�o�ɐU��
               ,customer_sample_ship                  -- 26.�ڋq���{�o��
               ,customer_sample_ship_b                -- 27.�ڋq���{�o�ɐU��
               ,customer_support_ss                   -- 28.�ڋq���^���{�o��
               ,customer_support_ss_b                 -- 29.�ڋq���^���{�o�ɐU��
               ,vd_supplement_stock                   -- 32.����VD��[����
               ,vd_supplement_ship                    -- 33.����VD��[�o��
               ,inventory_change_in                   -- 34.��݌ɕύX����
               ,inventory_change_out                  -- 35.��݌ɕύX�o��
               ,factory_return                        -- 36.�H��ԕi
               ,factory_return_b                      -- 37.�H��ԕi�U��
               ,factory_change                        -- 38.�H��q��
               ,factory_change_b                      -- 39.�H��q�֐U��
               ,removed_goods                         -- 40.�p�p
               ,removed_goods_b                       -- 41.�p�p�U��
               ,factory_stock                         -- 42.�H�����
               ,factory_stock_b                       -- 43.�H����ɐU��
               ,ccm_sample_ship                       -- 30.�ڋq�L����`��A���Џ��i
               ,ccm_sample_ship_b                     -- 31.�ڋq�L����`��A���Џ��i�U��
               ,wear_decrease                         -- 44.�I�����Ց�
               ,wear_increase                         -- 45.�I�����Ռ�
               ,selfbase_ship                         -- 46.�ۊǏꏊ�ړ��Q�����_�o��
               ,selfbase_stock                        -- 47.�ۊǏꏊ�ړ��Q�����_����
               ,book_inventory_quantity               -- 48.����݌ɐ�
               ,last_update_date                      -- 49.�ŏI�X�V��
               ,last_updated_by                       -- 50.�ŏI�X�V��
               ,creation_date                         -- 51.�쐬��
               ,created_by                            -- 52.�쐬��
               ,last_update_login                     -- 53.�ŏI�X�V���[�U
               ,request_id                            -- 54.�v��ID
               ,program_application_id                -- 55.�v���O�����A�v���P�[�V����ID
               ,program_id                            -- 56.�v���O����ID
               ,program_update_date                   -- 57.�v���O�����X�V��
              )VALUES(
                lt_base_code                          -- 01
               ,gn_f_organization_id                  -- 02
               ,lt_subinventory_code                  -- 03
               ,gd_f_business_date                    -- 04
               ,lt_inventory_item_id                  -- 05
               ,lt_subinventory_type                  -- 06
               ,lt_operation_cost                     -- 07
               ,lt_standard_cost                      -- 08
               ,lt_book_inventory_quantity            -- 09
               ,0                                     -- 10
               ,0                                     -- 11
               ,0                                     -- 12
               ,0                                     -- 13
               ,0                                     -- 14
               ,0                                     -- 15
               ,0                                     -- 16
               ,0                                     -- 17
               ,0                                     -- 18
               ,0                                     -- 19
               ,0                                     -- 20
               ,0                                     -- 21
               ,0                                     -- 22
               ,0                                     -- 23
               ,0                                     -- 24
               ,0                                     -- 25
               ,0                                     -- 26
               ,0                                     -- 27
               ,0                                     -- 28
               ,0                                     -- 29
               ,0                                     -- 32
               ,0                                     -- 33
               ,0                                     -- 34
               ,0                                     -- 35
               ,0                                     -- 36
               ,0                                     -- 37
               ,0                                     -- 38
               ,0                                     -- 39
               ,0                                     -- 40
               ,0                                     -- 41
               ,0                                     -- 42
               ,0                                     -- 43
               ,0                                     -- 30
               ,0                                     -- 31
               ,0                                     -- 44
               ,0                                     -- 45
               ,0                                     -- 46
               ,0                                     -- 47
               ,lt_book_inventory_quantity            -- 48
               ,SYSDATE                               -- 49
               ,cn_last_updated_by                    -- 50
               ,SYSDATE                               -- 51
               ,cn_created_by                         -- 52
               ,cn_last_update_login                  -- 53
               ,cn_request_id                         -- 54
               ,cn_program_application_id             -- 55
               ,cn_program_id                         -- 56
               ,SYSDATE                               -- 57
              );
              --
---- == 2009/08/26 V1.8 Added START ===============================================================
              gn_target_cnt := gn_target_cnt + 1;
---- == 2009/08/26 V1.8 Added END   ===============================================================
          END;
          --
-- == 2009/08/26 V1.8 Deleted START ===============================================================
---- == 2009/05/28 V1.4 Added START ===============================================================
--          -- �݌v�e�[�u���쐬�p�N����ݒ�
--          lt_practice_date  :=  gd_f_max_practice_date;
---- == 2009/05/28 V1.4 Added START ===============================================================
-- == 2009/08/26 V1.8 Deleted END   ===============================================================
        END IF;
        --
-- == 2009/08/26 V1.8 Deleted START ===============================================================
---- == 2009/05/28 V1.4 Added START ===============================================================
---- == 2009/06/05 V1.6 Added START ===============================================================
--          -- �݌v�e�[�u���쐬�p�N�����ݒ肳��Ă���ꍇ�A�݌v�����쐬
--        IF (lt_practice_date  IS NOT NULL)  THEN
---- == 2009/06/05 V1.6 Added START ===============================================================
--          -- ==============================================
--          --  A-8.�݌v�󕥃f�[�^�o��
--          -- ==============================================
--          set_reception_sum(
--            it_base_code                =>  lt_base_code                          -- 01.���_�R�[�h
--           ,it_subinventory_code        =>  lt_subinventory_code                  -- 03.�ۊǏꏊ
--           ,it_practice_date            =>  lt_practice_date                      -- 04.�N����
--           ,it_inventory_item_id        =>  lt_inventory_item_id                  -- 05.�i��ID
--           ,it_subinventory_type        =>  lt_subinventory_type                  -- 06.�ۊǏꏊ�敪
--           ,it_operation_cost           =>  lt_operation_cost                     -- 07.�c�ƌ���
--           ,it_standard_cost            =>  lt_standard_cost                      -- 08.�W������
--           ,it_sales_shipped            =>  lt_sales_shipped                      -- 10.����o��
--           ,it_sales_shipped_b          =>  lt_sales_shipped_b                    -- 11.����o�ɐU��
--           ,it_return_goods             =>  lt_return_goods                       -- 12.�ԕi
--           ,it_return_goods_b           =>  lt_return_goods_b                     -- 13.�ԕi�U��
--           ,it_warehouse_ship           =>  lt_warehouse_ship                     -- 14.�q�ɂ֕Ԍ�
--           ,it_truck_ship               =>  lt_truck_ship                         -- 15.�c�ƎԂ֏o��
--           ,it_others_ship              =>  lt_others_ship                        -- 16.���o�ɁQ���̑��o��
--           ,it_warehouse_stock          =>  lt_warehouse_stock                    -- 17.�q�ɂ�����
--           ,it_truck_stock              =>  lt_truck_stock                        -- 18.�c�ƎԂ�����
--           ,it_others_stock             =>  lt_others_stock                       -- 19.���o�ɁQ���̑�����
--           ,it_change_stock             =>  lt_change_stock                       -- 20.�q�֓���
--           ,it_change_ship              =>  lt_change_ship                        -- 21.�q�֏o��
--           ,it_goods_transfer_old       =>  lt_goods_transfer_old                 -- 22.���i�U�ցi�����i�j
--           ,it_goods_transfer_new       =>  lt_goods_transfer_new                 -- 23.���i�U�ցi�V���i�j
--           ,it_sample_quantity          =>  lt_sample_quantity                    -- 24.���{�o��
--           ,it_sample_quantity_b        =>  lt_sample_quantity_b                  -- 25.���{�o�ɐU��
--           ,it_customer_sample_ship     =>  lt_customer_sample_ship               -- 26.�ڋq���{�o��
--           ,it_customer_sample_ship_b   =>  lt_customer_sample_ship_b             -- 27.�ڋq���{�o�ɐU��
--           ,it_customer_support_ss      =>  lt_customer_support_ss                -- 28.�ڋq���^���{�o��
--           ,it_customer_support_ss_b    =>  lt_customer_support_ss_b              -- 29.�ڋq���^���{�o�ɐU��
--           ,it_vd_supplement_stock      =>  lt_vd_supplement_stock                -- 32.����VD��[����
--           ,it_vd_supplement_ship       =>  lt_vd_supplement_ship                 -- 33.����VD��[�o��
--           ,it_inventory_change_in      =>  lt_inventory_change_in                -- 34.��݌ɕύX����
--           ,it_inventory_change_out     =>  lt_inventory_change_out               -- 35.��݌ɕύX�o��
--           ,it_factory_return           =>  lt_factory_return                     -- 36.�H��ԕi
--           ,it_factory_return_b         =>  lt_factory_return_b                   -- 37.�H��ԕi�U��
--           ,it_factory_change           =>  lt_factory_change                     -- 38.�H��q��
--           ,it_factory_change_b         =>  lt_factory_change_b                   -- 39.�H��q�֐U��
--           ,it_removed_goods            =>  lt_removed_goods                      -- 40.�p�p
--           ,it_removed_goods_b          =>  lt_removed_goods_b                    -- 41.�p�p�U��
--           ,it_factory_stock            =>  lt_factory_stock                      -- 42.�H�����
--           ,it_factory_stock_b          =>  lt_factory_stock_b                    -- 43.�H����ɐU��
--           ,it_ccm_sample_ship          =>  lt_ccm_sample_ship                    -- 30.�ڋq�L����`��A���Џ��i
--           ,it_ccm_sample_ship_b        =>  lt_ccm_sample_ship_b                  -- 31.�ڋq�L����`��A���Џ��i�U��
--           ,it_wear_decrease            =>  lt_wear_decrease                      -- 44.�I�����Ց�
--           ,it_wear_increase            =>  lt_wear_increase                      -- 45.�I�����Ռ�
--           ,it_selfbase_ship            =>  lt_selfbase_ship                      -- 46.�ۊǏꏊ�ړ��Q�����_�o��
--           ,it_selfbase_stock           =>  lt_selfbase_stock                     -- 47.�ۊǏꏊ�ړ��Q�����_����
--           ,it_book_inventory_quantity  =>  lt_book_inventory_quantity            -- 48.����݌ɐ�
--           ,ib_chk_result               =>  lb_chk_result                         -- 49.�݌ɉ�v����OPEN����
--           ,ov_errbuf                   =>  lv_errbuf       --   �G���[�E���b�Z�[�W           --# �Œ� #
--           ,ov_retcode                  =>  lv_retcode      --   ���^�[���E�R�[�h             --# �Œ� #
--           ,ov_errmsg                   =>  lv_errmsg       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--          );
--          -- �I���p�����[�^����
--          IF (lv_retcode = cv_status_error) THEN
--            RAISE global_process_expt;
--          END IF;
---- == 2009/06/05 V1.6 Added START ===============================================================
--        END IF;
---- == 2009/06/05 V1.6 Added START ===============================================================
---- == 2009/05/28 V1.4 Added END   ===============================================================
-- == 2009/08/26 V1.8 Deleted END   ===============================================================
        -- �W�v���ڏ�����
        FOR i IN  1 .. 38 LOOP
          gt_quantity(i)  :=  0;
        END LOOP;
        --
      END IF;
      --
      -- �I������
      EXIT set_material_loop WHEN material_transaction_cur%NOTFOUND;
      --
      -- �󕥏W�v�i����^�C�v�ʁj
      CASE  material_transaction_rec.transaction_type
        WHEN  cv_trans_type_010  THEN   -- 01.����o��
          gt_quantity(1)   :=  gt_quantity(1) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_020  THEN   -- 02.����o�ɐU��
          gt_quantity(2)   :=  gt_quantity(2) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_030  THEN   -- 03.�ԕi
          gt_quantity(3)   :=  gt_quantity(3) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_040  THEN   -- 04.�ԕi�U��
          gt_quantity(4)   :=  gt_quantity(4) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_050  THEN
          IF (    (material_transaction_rec.transaction_qty    < 0)
              AND (material_transaction_rec.inventory_type     = cv_subinv_2)
              AND (material_transaction_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
             )
          THEN
            -- 05.�q�ɂ֕Ԍ�
            gt_quantity(5)   :=  gt_quantity(5) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    < 0)
                 AND (material_transaction_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (material_transaction_rec.subinventory_type  = cv_subinv_2)
                )
          THEN
            -- 06.�c�ƎԂ֏o��
            gt_quantity(6)   :=  gt_quantity(6) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    < 0)
                 AND (material_transaction_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (material_transaction_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                )
          THEN
            -- 07.���o�ɁQ���̑��o��
            gt_quantity(7)   :=  gt_quantity(7) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    > 0)
                 AND (material_transaction_rec.inventory_type     = cv_subinv_2)
                 AND (material_transaction_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                )
          THEN
            -- 08.�q�ɂ�����
            gt_quantity(8)   :=  gt_quantity(8) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    > 0)
                 AND (material_transaction_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (material_transaction_rec.subinventory_type  = cv_subinv_2)
                )
          THEN
            -- 09.�c�ƎԂ�����
            gt_quantity(9)   :=  gt_quantity(9) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    > 0)
                 AND (material_transaction_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (material_transaction_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                )
          THEN
            -- 10.���o�ɁQ���̑�����
            gt_quantity(10)  :=  gt_quantity(10) + material_transaction_rec.transaction_qty;
            --
          END IF;
        WHEN  cv_trans_type_060  THEN
-- == 2009/05/14 V1.3 Modified START ===============================================================
--          IF (material_transaction_rec.transaction_qty >= 0) THEN
--            -- 11.�q�֓���
--            gt_quantity(11)  :=  gt_quantity(11) + material_transaction_rec.transaction_qty;
--          ELSIF (material_transaction_rec.transaction_qty < 0) THEN
--            -- 12.�q�֏o��
--            gt_quantity(12)  :=  gt_quantity(12) + material_transaction_rec.transaction_qty;
--          END IF;
--
          IF (    (material_transaction_rec.transaction_qty    < 0)
              AND (material_transaction_rec.inventory_type     = cv_subinv_2)
              AND (material_transaction_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
             )
          THEN
            -- 05.�q�ɂ֕Ԍ�
            gt_quantity(5)   :=  gt_quantity(5) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    < 0)
                 AND (material_transaction_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (material_transaction_rec.subinventory_type  = cv_subinv_2)
                )
          THEN
            -- 06.�c�ƎԂ֏o��
            gt_quantity(6)   :=  gt_quantity(6) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    < 0)
                 AND (material_transaction_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (material_transaction_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                )
          THEN
            -- 12.�q�֏o��
            gt_quantity(12)  :=  gt_quantity(12) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    > 0)
                 AND (material_transaction_rec.inventory_type     = cv_subinv_2)
                 AND (material_transaction_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                )
          THEN
            -- 08.�q�ɂ�����
            gt_quantity(8)   :=  gt_quantity(8) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    > 0)
                 AND (material_transaction_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (material_transaction_rec.subinventory_type  = cv_subinv_2)
                )
          THEN
            -- 09.�c�ƎԂ�����
            gt_quantity(9)   :=  gt_quantity(9) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    > 0)
                 AND (material_transaction_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (material_transaction_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                )
          THEN
            -- 11.�q�֓���
            gt_quantity(11)  :=  gt_quantity(11) + material_transaction_rec.transaction_qty;
            --
          END IF;
-- == 2009/05/14 V1.3 Modified END   ===============================================================
        WHEN  cv_trans_type_070  THEN   -- 13.���i�U�ցi�����i�j
          gt_quantity(13)  :=  gt_quantity(13) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_080  THEN   -- 14.���i�U�ցi�V���i�j
          gt_quantity(14)  :=  gt_quantity(14) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_090  THEN   -- 15.���{�o��
          gt_quantity(15)  :=  gt_quantity(15) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_100 THEN   -- 16.���{�o�ɐU��
          gt_quantity(16)  :=  gt_quantity(16) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_110 THEN   -- 17.�ڋq���{�o��
          gt_quantity(17)  :=  gt_quantity(17) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_120 THEN   -- 18.�ڋq���{�o�ɐU��
          gt_quantity(18)  :=  gt_quantity(18) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_130 THEN   -- 19.�ڋq���^���{�o��
          gt_quantity(19)  :=  gt_quantity(19) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_140 THEN   -- 20.�ڋq���^���{�o�ɐU��
          gt_quantity(20)  :=  gt_quantity(20) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_150 THEN
          IF (material_transaction_rec.transaction_qty >= 0) THEN
            -- 21.����VD��[����
            gt_quantity(21)  :=  gt_quantity(21) + material_transaction_rec.transaction_qty;
          ELSIF (material_transaction_rec.transaction_qty < 0) THEN
            -- 22.����VD��[�o��
            gt_quantity(22)  :=  gt_quantity(22) + material_transaction_rec.transaction_qty;
          END IF;
        WHEN  cv_trans_type_160 THEN
-- == 2009/06/04 V1.5 Modified START ===============================================================
--          IF (material_transaction_rec.transaction_qty   >= 0) THEN
--            -- 23.��݌ɕύX����
--            gt_quantity(23)  :=  gt_quantity(23) + material_transaction_rec.transaction_qty;
--          ELSIF (material_transaction_rec.transaction_qty < 0) THEN
--            -- 24.��݌ɕύX�o��
--            gt_quantity(24)  :=  gt_quantity(24) + material_transaction_rec.transaction_qty;
--          END IF;
--
          IF (material_transaction_rec.subinv_class = cv_subinv_class_7)  THEN
            -- ����VD�͑ΏۊO
            NULL;
          ELSIF (material_transaction_rec.transaction_qty   >= 0) THEN
            -- 23.��݌ɕύX����
            gt_quantity(23)  :=  gt_quantity(23) + material_transaction_rec.transaction_qty;
          ELSIF (material_transaction_rec.transaction_qty < 0) THEN
            -- 24.��݌ɕύX�o��
            gt_quantity(24)  :=  gt_quantity(24) + material_transaction_rec.transaction_qty;
          END IF;
-- == 2009/06/04 V1.5 Modified END   ===============================================================
        WHEN  cv_trans_type_170 THEN   -- 25.�H��ԕi
          gt_quantity(25)  :=  gt_quantity(25) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_180 THEN   -- 26.�H��ԕi�U��
          gt_quantity(26)  :=  gt_quantity(26) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_190 THEN   -- 27.�H��q��
          gt_quantity(27)  :=  gt_quantity(27) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_200 THEN   -- 28.�H��q�֐U��
          gt_quantity(28)  :=  gt_quantity(28) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_210 THEN   -- 29.�p�p
          gt_quantity(29)  :=  gt_quantity(29) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_220 THEN   -- 30.�p�p�U��
          gt_quantity(30)  :=  gt_quantity(30) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_230 THEN   -- 31.�H�����
          gt_quantity(31)  :=  gt_quantity(31) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_240 THEN   -- 32.�H����ɐU��
          gt_quantity(32)  :=  gt_quantity(32) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_250 THEN   -- 33.�ڋq�L����`��A���Џ��i
          gt_quantity(33)  :=  gt_quantity(33) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_260 THEN   -- 34.�ڋq�L����`��A���Џ��i�U��
          gt_quantity(34)  :=  gt_quantity(34) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_270 THEN   -- 35.�I�����Ց�
          gt_quantity(35)  :=  gt_quantity(35) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_280 THEN   -- 36.�I�����Ռ�
          gt_quantity(36)  :=  gt_quantity(36) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_290 THEN
-- == 2009/05/08 V1.2 Deleted START ===============================================================
--          IF (material_transaction_rec.base_code = material_transaction_rec.sub_base_code) THEN
-- == 2009/05/08 V1.2 Deleted END   ===============================================================
            IF (material_transaction_rec.transaction_qty < 0) THEN
              -- 37.�ۊǏꏊ�ړ��Q�����_�o��
              gt_quantity(37)  :=  gt_quantity(37) + material_transaction_rec.transaction_qty;
            ELSIF (material_transaction_rec.transaction_qty >= 0) THEN
              -- 38.�ۊǏꏊ�ړ��Q�����_����
              gt_quantity(38)  :=  gt_quantity(38) + material_transaction_rec.transaction_qty;
            END IF;
-- == 2009/05/08 V1.2 Deleted START ===============================================================
--          END IF;
-- == 2009/05/08 V1.2 Deleted END   ===============================================================
        ELSE  NULL;
      END CASE;
      --
      -- ���R�[�h�ύX�`�F�b�N�p�ϐ��ێ�
      lt_base_code                :=  material_transaction_rec.base_code;
      lt_subinventory_code        :=  material_transaction_rec.subinventory_code;
      lt_inventory_item_id        :=  material_transaction_rec.inventory_item_id;
      lv_transaction_month        :=  material_transaction_rec.transaction_month;
      lt_transaction_date         :=  material_transaction_rec.transaction_date;
      lt_last_book_inv_quantity   :=  material_transaction_rec.last_book_inv_quantity;
      lt_today_book_inv_quantity  :=  material_transaction_rec.today_book_inv_quantity;
      lt_subinventory_type        :=  material_transaction_rec.inventory_type;
      --
      ln_material_flag    :=  1;
      FETCH material_transaction_cur  INTO  material_transaction_rec;
      --
    END LOOP set_material_loop;
    --
    CLOSE material_transaction_cur;
-- == 2009/10/15 V1.11 Added START ===============================================================
    gn_material_flag    :=  ln_material_flag;
-- == 2009/10/15 V1.11 Added START ===============================================================
    --
    IF (ln_today_data = 0) THEN
      -- ���ގ���i�������j�f�[�^�Ȃ�
      ov_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_short_name
                       ,iv_name         =>  cv_msg_xxcoi1_10128
                      );
      ov_errbuf   :=  ov_errmsg;
      ov_retcode  :=  cv_status_warn;
      gn_warn_cnt :=  gn_warn_cnt + 1;      -- �x�������J�E���g
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
  END set_mtl_transaction_data;
--
-- == 2009/08/26 V1.8 Added START ===============================================================
  /**********************************************************************************
   * Procedure Name   : set_mtl_transaction_data2
   * Description      : �����f�[�^�����݌Ɏ󕥁i�݌v�j�o��(A-10, A-11)
   ***********************************************************************************/
  PROCEDURE set_mtl_transaction_data2(
    ov_errbuf         OUT VARCHAR2,                     -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode        OUT VARCHAR2,                     -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg         OUT VARCHAR2)                     -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_mtl_transaction_data2'; -- �v���O������
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
    lb_chk_result                   BOOLEAN;        -- �݌ɉ�v����OPEN�t���O�iOPEN:TRUE, CLOSE:FALSE�j
    ln_material_flag                NUMBER  := 0;   -- ���ގ���f�[�^�擾�t���O
    ln_today_data                   NUMBER  := 0;   -- ���ގ���������f�[�^����
    --
    lt_base_code                    xxcoi_inv_reception_daily.base_code%TYPE;               -- ���_�R�[�h
    lt_subinventory_code            xxcoi_inv_reception_daily.subinventory_code%TYPE;       -- �ۊǏꏊ�R�[�h
    lt_inventory_item_id            xxcoi_inv_reception_daily.inventory_item_id%TYPE;       -- �i��ID
    lv_transaction_month            VARCHAR2(6);                                            -- ����N��
    lt_transaction_date             mtl_material_transactions.transaction_date%TYPE;        -- �����
    lt_subinventory_type            xxcoi_inv_reception_daily.subinventory_type%TYPE;       -- �ۊǏꏊ�敪
    lt_standard_cost                xxcoi_inv_reception_daily.standard_cost%TYPE;           -- �W������
    lt_operation_cost               xxcoi_inv_reception_daily.operation_cost%TYPE;          -- �c�ƌ���
    lt_sales_shipped                xxcoi_inv_reception_daily.sales_shipped%TYPE;           -- ����o��
    lt_sales_shipped_b              xxcoi_inv_reception_daily.sales_shipped_b%TYPE;         -- ����o�ɐU��
    lt_return_goods                 xxcoi_inv_reception_daily.return_goods%TYPE;            -- �ԕi
    lt_return_goods_b               xxcoi_inv_reception_daily.return_goods_b%TYPE;          -- �ԕi�U��
    lt_warehouse_ship               xxcoi_inv_reception_daily.warehouse_ship%TYPE;          -- �q�ɂ֕Ԍ�
    lt_truck_ship                   xxcoi_inv_reception_daily.truck_ship%TYPE;              -- �c�ƎԂ֏o��
    lt_others_ship                  xxcoi_inv_reception_daily.others_ship%TYPE;             -- ���o�ɁQ���̑��o��
    lt_warehouse_stock              xxcoi_inv_reception_daily.warehouse_stock%TYPE;         -- �q�ɂ�����
    lt_truck_stock                  xxcoi_inv_reception_daily.truck_stock%TYPE;             -- �c�ƎԂ�����
    lt_others_stock                 xxcoi_inv_reception_daily.others_stock%TYPE;            -- ���o�ɁQ���̑�����
    lt_change_stock                 xxcoi_inv_reception_daily.change_stock%TYPE;            -- �q�֓���
    lt_change_ship                  xxcoi_inv_reception_daily.change_ship%TYPE;             -- �q�֏o��
    lt_goods_transfer_old           xxcoi_inv_reception_daily.goods_transfer_old%TYPE;      -- ���i�U�ցi�����i�j
    lt_goods_transfer_new           xxcoi_inv_reception_daily.goods_transfer_new%TYPE;      -- ���i�U�ցi�V���i�j
    lt_sample_quantity              xxcoi_inv_reception_daily.sample_quantity%TYPE;         -- ���{�o��
    lt_sample_quantity_b            xxcoi_inv_reception_daily.sample_quantity_b%TYPE;       -- ���{�o�ɐU��
    lt_customer_sample_ship         xxcoi_inv_reception_daily.customer_sample_ship%TYPE;    -- �ڋq���{�o��
    lt_customer_sample_ship_b       xxcoi_inv_reception_daily.customer_sample_ship_b%TYPE;  -- �ڋq���{�o�ɐU��
    lt_customer_support_ss          xxcoi_inv_reception_daily.customer_support_ss%TYPE;     -- �ڋq���^���{�o��
    lt_customer_support_ss_b        xxcoi_inv_reception_daily.customer_support_ss_b%TYPE;   -- �ڋq���^���{�o�ɐU��
    lt_vd_supplement_stock          xxcoi_inv_reception_daily.vd_supplement_stock%TYPE;     -- ����VD��[����
    lt_vd_supplement_ship           xxcoi_inv_reception_daily.vd_supplement_ship%TYPE;      -- ����VD��[�o��
    lt_inventory_change_in          xxcoi_inv_reception_daily.inventory_change_in%TYPE;     -- ��݌ɕύX����
    lt_inventory_change_out         xxcoi_inv_reception_daily.inventory_change_out%TYPE;    -- ��݌ɕύX�o��
    lt_factory_return               xxcoi_inv_reception_daily.factory_return%TYPE;          -- �H��ԕi
    lt_factory_return_b             xxcoi_inv_reception_daily.factory_return_b%TYPE;        -- �H��ԕi�U��
    lt_factory_change               xxcoi_inv_reception_daily.factory_change%TYPE;          -- �H��q��
    lt_factory_change_b             xxcoi_inv_reception_daily.factory_change_b%TYPE;        -- �H��q�֐U��
    lt_removed_goods                xxcoi_inv_reception_daily.removed_goods%TYPE;           -- �p�p
    lt_removed_goods_b              xxcoi_inv_reception_daily.removed_goods_b%TYPE;         -- �p�p�U��
    lt_factory_stock                xxcoi_inv_reception_daily.factory_stock%TYPE;           -- �H�����
    lt_factory_stock_b              xxcoi_inv_reception_daily.factory_stock_b%TYPE;         -- �H����ɐU��
    lt_ccm_sample_ship              xxcoi_inv_reception_daily.ccm_sample_ship%TYPE;         -- �ڋq�L����`��A���Џ��i
    lt_ccm_sample_ship_b            xxcoi_inv_reception_daily.ccm_sample_ship_b%TYPE;       -- �ڋq�L����`��A���Џ��i�U��
    lt_wear_decrease                xxcoi_inv_reception_daily.wear_decrease%TYPE;           -- �I�����Ց�
    lt_wear_increase                xxcoi_inv_reception_daily.wear_increase%TYPE;           -- �I�����Ռ�
    lt_selfbase_ship                xxcoi_inv_reception_daily.selfbase_ship%TYPE;           -- �ۊǏꏊ�ړ��Q�����_�o��
    lt_selfbase_stock               xxcoi_inv_reception_daily.selfbase_stock%TYPE;          -- �ۊǏꏊ�ړ��Q�����_����
    lt_book_inventory_quantity      xxcoi_inv_reception_daily.book_inventory_quantity%TYPE; -- ����݌ɐ�
    lt_practice_date                xxcoi_inv_reception_daily.practice_date%TYPE;           -- �N��
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���ގ���f�[�^�擾(�݌v�p)
    CURSOR  material_transaction_cur
    IS
      SELECT  /*+ LEADING(MMT)
                  USE_NL(MMT MSI1 MTT)
                  USE_NL(MMT MSI2)
                  INDEX(MMT MTL_MATERIAL_TRANSACTIONS_U1)
                  */
              msi1.attribute7                         base_code                   -- ���_�R�[�h
             ,msi1.attribute1                         inventory_type              -- �ۊǏꏊ�敪
             ,msi2.attribute7                         sub_base_code               -- ����拒�_�R�[�h
             ,msi2.attribute1                         subinventory_type           -- �����ۊǏꏊ�敪
             ,mmt.subinventory_code                   subinventory_code           -- �ۊǏꏊ�R�[�h
             ,mtt.attribute3                          transaction_type            -- �󕥕\�W�v�L�[
             ,mmt.inventory_item_id                   inventory_item_id           -- �i��ID
             ,TO_CHAR(mmt.transaction_date, cv_month) transaction_month           -- ����N��
             ,TRUNC(mmt.transaction_date)             transaction_date            -- �����
             ,mmt.primary_quantity                    transaction_qty             -- ��P�ʐ���
             ,msi1.attribute13                        subinv_class                -- �ۊǏꏊ����
      FROM    mtl_material_transactions     mmt                                   -- ���ގ���e�[�u��
             ,mtl_secondary_inventories     msi1                                  -- �ۊǏꏊ
             ,mtl_secondary_inventories     msi2                                  -- �ۊǏꏊ
             ,mtl_transaction_types         mtt                                   -- ����^�C�v�}�X�^
      WHERE   mmt.organization_id         =   gn_f_organization_id
      AND     mmt.transaction_id          >   gn_f_last_transaction_id
      AND     mmt.transaction_id         <=   gn_f_max_transaction_id
      AND     TRUNC(mmt.transaction_date)
                  BETWEEN TO_DATE(TO_CHAR(ADD_MONTHS(gd_f_business_date, -1), cv_month) || '01', cv_date)
                  AND     gd_f_business_date
      AND     mmt.subinventory_code       =   msi1.secondary_inventory_name
      AND     mmt.organization_id         =   msi1.organization_id
      AND     mmt.transfer_subinventory   =   msi2.secondary_inventory_name(+)
      AND     mmt.transfer_organization_id =  msi2.organization_id(+)
      AND     msi1.attribute1            <>   cv_inv_type_5
      AND     msi1.attribute1            <>   cv_inv_type_8
      AND     mmt.transaction_type_id     =   mtt.transaction_type_id
      AND     mtt.attribute3       IS NOT NULL
      ORDER BY  msi1.attribute7
               ,mmt.subinventory_code
               ,mmt.inventory_item_id
               ,mmt.transaction_date  DESC;
    --
    -- ���ގ���f�[�^�擾���R�[�h�^
    material_transaction_rec    material_transaction_cur%ROWTYPE;
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
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    -- ===================================
    --  1.�݌ɉ�v����CLOSE�`�F�b�N
    -- ===================================
    xxcoi_common_pkg.org_acct_period_chk(
       in_organization_id   =>  gn_f_organization_id                  -- �g�DID
      ,id_target_date       =>  ADD_MONTHS(gd_f_business_date, -1)    -- �Ɩ��������t�̑O��
      ,ob_chk_result        =>  lb_chk_result                         -- �`�F�b�N����
      ,ov_errbuf            =>  lv_errbuf
      ,ov_retcode           =>  lv_retcode
      ,ov_errmsg            =>  lv_errmsg
    );
    -- �I������
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- ===================================
    --  �����f�[�^�쐬
    -- ===================================
    -- �J�[�\��OPEN
    OPEN  material_transaction_cur;
    FETCH material_transaction_cur  INTO  material_transaction_rec;
    --
    lt_base_code                :=  material_transaction_rec.base_code;
    lt_subinventory_code        :=  material_transaction_rec.subinventory_code;
    lt_inventory_item_id        :=  material_transaction_rec.inventory_item_id;
    lv_transaction_month        :=  material_transaction_rec.transaction_month;
    --
    <<set_material_loop>>
    LOOP
      -- ���ގ���f�[�^���P�����擾����Ȃ��ꍇ�ALOOP�����I��
      EXIT set_material_loop WHEN material_transaction_cur%NOTFOUND AND ln_material_flag = 0;
      --
      -- ���_�A�ۊǏꏊ�A�i�ځA������i�N���j�̂����ꂩ���O���R�[�h�ƈ�v���Ȃ��ꍇ�A�܂��́A
      -- �ŏI���R�[�h�̏���������̏ꍇ�A�����f�[�^��}���A�܂��́A�X�V
      IF (    (material_transaction_rec.base_code          <>  lt_base_code)
          OR  (material_transaction_rec.subinventory_code  <>  lt_subinventory_code)
          OR  (material_transaction_rec.inventory_item_id  <>  lt_inventory_item_id)
          OR  (material_transaction_rec.transaction_month  <>  lv_transaction_month)
          OR  (material_transaction_cur%NOTFOUND)
         )
      THEN
        --
        -- ===================================
        --  2.�W�������擾
        -- ===================================
        xxcoi_common_pkg.get_cmpnt_cost(
          in_item_id      =>  lt_inventory_item_id                            -- �i��ID
         ,in_org_id       =>  gn_f_organization_id                            -- �g�DID
         ,id_period_date  =>  lt_transaction_date                             -- �Ώۓ�
         ,ov_cmpnt_cost   =>  lt_standard_cost                                -- �W������
         ,ov_errbuf       =>  lv_errbuf                                       -- �G���[���b�Z�[�W
         ,ov_retcode      =>  lv_retcode                                      -- ���^�[���E�R�[�h
         ,ov_errmsg       =>  lv_errmsg                                       -- ���[�U�[�E�G���[���b�Z�[�W
        );
        -- �I���p�����[�^����
        IF (lv_retcode = cv_status_error) THEN
          lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application  => cv_short_name
                          ,iv_name         => cv_msg_xxcoi1_10285
                         );
          lv_errbuf   := lv_errmsg;
          RAISE global_api_expt;
        END IF;
        --
        -- ===================================
        --  2.�c�ƌ����擾
        -- ===================================
        xxcoi_common_pkg.get_discrete_cost(
          in_item_id        =>  lt_inventory_item_id                            -- �i��ID
         ,in_org_id         =>  gn_f_organization_id                            -- �g�DID
         ,id_target_date    =>  lt_transaction_date                             -- �Ώۓ�
         ,ov_discrete_cost  =>  lt_operation_cost                               -- �c�ƌ���
         ,ov_errbuf         =>  lv_errbuf                                       -- �G���[���b�Z�[�W
         ,ov_retcode        =>  lv_retcode                                      -- ���^�[���E�R�[�h
         ,ov_errmsg         =>  lv_errmsg                                       -- ���[�U�[�E�G���[���b�Z�[�W
        );
        -- �I���p�����[�^����
        IF (lv_retcode = cv_status_error) THEN
          lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application  => cv_short_name
                          ,iv_name         => cv_msg_xxcoi1_10293
                         );
          lv_errbuf   := lv_errmsg;
          RAISE global_api_expt;
        END IF;
        --
        -- ==========================
        --  �X�V�p�f�[�^�ݒ�
        -- ==========================
        lt_sales_shipped            :=  gt_quantity(1)  * -1  ;       -- ����o��
        lt_sales_shipped_b          :=  gt_quantity(2)        ;       -- ����o�ɐU��
        lt_return_goods             :=  gt_quantity(3)        ;       -- �ԕi
        lt_return_goods_b           :=  gt_quantity(4)  * -1  ;       -- �ԕi�U��
        lt_warehouse_ship           :=  gt_quantity(5)  * -1  ;       -- �q�ɂ֕Ԍ�
        lt_truck_ship               :=  gt_quantity(6)  * -1  ;       -- �c�ƎԂ֏o��
        lt_others_ship              :=  gt_quantity(7)  * -1  ;       -- ���o�ɁQ���̑��o��
        lt_warehouse_stock          :=  gt_quantity(8)        ;       -- �q�ɂ�����
        lt_truck_stock              :=  gt_quantity(9)        ;       -- �c�ƎԂ�����
        lt_others_stock             :=  gt_quantity(10)       ;       -- ���o�ɁQ���̑�����
        lt_change_stock             :=  gt_quantity(11)       ;       -- �q�֓���
        lt_change_ship              :=  gt_quantity(12) * -1  ;       -- �q�֏o��
        lt_goods_transfer_old       :=  gt_quantity(13) * -1  ;       -- ���i�U�ցi�����i�j
        lt_goods_transfer_new       :=  gt_quantity(14)       ;       -- ���i�U�ցi�V���i�j
        lt_sample_quantity          :=  gt_quantity(15) * -1  ;       -- ���{�o��
        lt_sample_quantity_b        :=  gt_quantity(16)       ;       -- ���{�o�ɐU��
        lt_customer_sample_ship     :=  gt_quantity(17) * -1  ;       -- �ڋq���{�o��
        lt_customer_sample_ship_b   :=  gt_quantity(18)       ;       -- �ڋq���{�o�ɐU��
        lt_customer_support_ss      :=  gt_quantity(19) * -1  ;       -- �ڋq���^���{�o��
        lt_customer_support_ss_b    :=  gt_quantity(20)       ;       -- �ڋq���^���{�o�ɐU��
        lt_vd_supplement_stock      :=  gt_quantity(21)       ;       -- ����VD��[����
        lt_vd_supplement_ship       :=  gt_quantity(22) * -1  ;       -- ����VD��[�o��
        lt_inventory_change_in      :=  gt_quantity(23)       ;       -- ��݌ɕύX����
        lt_inventory_change_out     :=  gt_quantity(24) * -1  ;       -- ��݌ɕύX�o��
        lt_factory_return           :=  gt_quantity(25) * -1  ;       -- �H��ԕi
        lt_factory_return_b         :=  gt_quantity(26)       ;       -- �H��ԕi�U��
        lt_factory_change           :=  gt_quantity(27) * -1  ;       -- �H��q��
        lt_factory_change_b         :=  gt_quantity(28)       ;       -- �H��q�֐U��
        lt_removed_goods            :=  gt_quantity(29) * -1  ;       -- �p�p
        lt_removed_goods_b          :=  gt_quantity(30)       ;       -- �p�p�U��
        lt_factory_stock            :=  gt_quantity(31)       ;       -- �H�����
        lt_factory_stock_b          :=  gt_quantity(32) * -1  ;       -- �H����ɐU��
        lt_ccm_sample_ship          :=  gt_quantity(33) * -1  ;       -- �ڋq�L����`��A���Џ��i
        lt_ccm_sample_ship_b        :=  gt_quantity(34)       ;       -- �ڋq�L����`��A���Џ��i�U��
        lt_wear_decrease            :=  gt_quantity(35)       ;       -- �I�����Ց�
        lt_wear_increase            :=  gt_quantity(36) * -1  ;       -- �I�����Ռ�
        lt_selfbase_ship            :=  gt_quantity(37) * -1  ;       -- �ۊǏꏊ�ړ��Q�����_�o��
        lt_selfbase_stock           :=  gt_quantity(38)       ;       -- �ۊǏꏊ�ړ��Q�����_����
        -- ����݌ɐ�
        lt_book_inventory_quantity  :=  gt_quantity(1)  + gt_quantity(2)  + gt_quantity(3)
                                      + gt_quantity(4)  + gt_quantity(5)  + gt_quantity(6)
                                      + gt_quantity(7)  + gt_quantity(8)  + gt_quantity(9)
                                      + gt_quantity(10) + gt_quantity(11) + gt_quantity(12)
                                      + gt_quantity(13) + gt_quantity(14) + gt_quantity(15)
                                      + gt_quantity(16) + gt_quantity(17) + gt_quantity(18)
                                      + gt_quantity(19) + gt_quantity(20) + gt_quantity(21)
                                      + gt_quantity(22) + gt_quantity(23) + gt_quantity(24)
                                      + gt_quantity(25) + gt_quantity(26) + gt_quantity(27)
                                      + gt_quantity(28) + gt_quantity(29) + gt_quantity(30)
                                      + gt_quantity(31) + gt_quantity(32) + gt_quantity(33)
                                      + gt_quantity(34) + gt_quantity(35) + gt_quantity(36)
                                      + gt_quantity(37) + gt_quantity(38);
        --
        IF (    (lt_sales_shipped            = 0)   -- ����o��
            AND (lt_sales_shipped_b          = 0)   -- ����o�ɐU��
            AND (lt_return_goods             = 0)   -- �ԕi
            AND (lt_return_goods_b           = 0)   -- �ԕi�U��
            AND (lt_warehouse_ship           = 0)   -- �q�ɂ֕Ԍ�
            AND (lt_truck_ship               = 0)   -- �c�ƎԂ֏o��
            AND (lt_others_ship              = 0)   -- ���o�ɁQ���̑��o��
            AND (lt_warehouse_stock          = 0)   -- �q�ɂ�����
            AND (lt_truck_stock              = 0)   -- �c�ƎԂ�����
            AND (lt_others_stock             = 0)   -- ���o�ɁQ���̑�����
            AND (lt_change_stock             = 0)   -- �q�֓���
            AND (lt_change_ship              = 0)   -- �q�֏o��
            AND (lt_goods_transfer_old       = 0)   -- ���i�U�ցi�����i�j
            AND (lt_goods_transfer_new       = 0)   -- ���i�U�ցi�V���i�j
            AND (lt_sample_quantity          = 0)   -- ���{�o��
            AND (lt_sample_quantity_b        = 0)   -- ���{�o�ɐU��
            AND (lt_customer_sample_ship     = 0)   -- �ڋq���{�o��
            AND (lt_customer_sample_ship_b   = 0)   -- �ڋq���{�o�ɐU��
            AND (lt_customer_support_ss      = 0)   -- �ڋq���^���{�o��
            AND (lt_customer_support_ss_b    = 0)   -- �ڋq���^���{�o�ɐU��
            AND (lt_vd_supplement_stock      = 0)   -- ����VD��[����
            AND (lt_vd_supplement_ship       = 0)   -- ����VD��[�o��
            AND (lt_inventory_change_in      = 0)   -- ��݌ɕύX����
            AND (lt_inventory_change_out     = 0)   -- ��݌ɕύX�o��
            AND (lt_factory_return           = 0)   -- �H��ԕi
            AND (lt_factory_return_b         = 0)   -- �H��ԕi�U��
            AND (lt_factory_change           = 0)   -- �H��q��
            AND (lt_factory_change_b         = 0)   -- �H��q�֐U��
            AND (lt_removed_goods            = 0)   -- �p�p
            AND (lt_removed_goods_b          = 0)   -- �p�p�U��
            AND (lt_factory_stock            = 0)   -- �H�����
            AND (lt_factory_stock_b          = 0)   -- �H����ɐU��
            AND (lt_ccm_sample_ship          = 0)   -- �ڋq�L����`��A���Џ��i
            AND (lt_ccm_sample_ship_b        = 0)   -- �ڋq�L����`��A���Џ��i�U��
            AND (lt_wear_decrease            = 0)   -- �I�����Ց�
            AND (lt_wear_increase            = 0)   -- �I�����Ռ�
            AND (lt_selfbase_ship            = 0)   -- �ۊǏꏊ�ړ��Q�����_�o��
            AND (lt_selfbase_stock           = 0)   -- �ۊǏꏊ�ړ��Q�����_����
            AND (lt_book_inventory_quantity  = 0)   -- ����݌ɐ�
           )
        THEN
          -- �S���ڂO�̏ꍇ�A�����݌Ɏ󕥕\���쐬���Ȃ�
          -- �݌v�e�[�u���쐬�p�N����ݒ�
          lt_practice_date  :=  NULL;
          --
        ELSIF (lv_transaction_month = TO_CHAR(gd_f_business_date, cv_month)) THEN
          -- ��������Ɩ��N���Ɠ���̏ꍇ�A�����f�[�^�Ƃ��ď���
          -- ���ގ���������f�[�^�����J�E���g
          ln_today_data     :=  ln_today_data + 1;
          -- �݌v�e�[�u���쐬�p�N����ݒ�(�Ɩ��������t)
          lt_practice_date  :=  gd_f_business_date;
        ELSE
          -- �݌v�e�[�u���쐬�p�N����ݒ�(�����ő�N����)
          lt_practice_date  :=  gd_f_max_practice_date;
        END IF;
          -- �݌v�e�[�u���쐬�p�N�����ݒ肳��Ă���ꍇ�A�݌v�����쐬
        IF (lt_practice_date  IS NOT NULL)  THEN
          -- ==============================================
          --  A-8.�݌v�󕥃f�[�^�o��
          -- ==============================================
          set_reception_sum(
            it_base_code                =>  lt_base_code                          -- 01.���_�R�[�h
           ,it_subinventory_code        =>  lt_subinventory_code                  -- 03.�ۊǏꏊ
           ,it_practice_date            =>  lt_practice_date                      -- 04.�N����
           ,it_inventory_item_id        =>  lt_inventory_item_id                  -- 05.�i��ID
           ,it_subinventory_type        =>  lt_subinventory_type                  -- 06.�ۊǏꏊ�敪
           ,it_operation_cost           =>  lt_operation_cost                     -- 07.�c�ƌ���
           ,it_standard_cost            =>  lt_standard_cost                      -- 08.�W������
           ,it_sales_shipped            =>  lt_sales_shipped                      -- 10.����o��
           ,it_sales_shipped_b          =>  lt_sales_shipped_b                    -- 11.����o�ɐU��
           ,it_return_goods             =>  lt_return_goods                       -- 12.�ԕi
           ,it_return_goods_b           =>  lt_return_goods_b                     -- 13.�ԕi�U��
           ,it_warehouse_ship           =>  lt_warehouse_ship                     -- 14.�q�ɂ֕Ԍ�
           ,it_truck_ship               =>  lt_truck_ship                         -- 15.�c�ƎԂ֏o��
           ,it_others_ship              =>  lt_others_ship                        -- 16.���o�ɁQ���̑��o��
           ,it_warehouse_stock          =>  lt_warehouse_stock                    -- 17.�q�ɂ�����
           ,it_truck_stock              =>  lt_truck_stock                        -- 18.�c�ƎԂ�����
           ,it_others_stock             =>  lt_others_stock                       -- 19.���o�ɁQ���̑�����
           ,it_change_stock             =>  lt_change_stock                       -- 20.�q�֓���
           ,it_change_ship              =>  lt_change_ship                        -- 21.�q�֏o��
           ,it_goods_transfer_old       =>  lt_goods_transfer_old                 -- 22.���i�U�ցi�����i�j
           ,it_goods_transfer_new       =>  lt_goods_transfer_new                 -- 23.���i�U�ցi�V���i�j
           ,it_sample_quantity          =>  lt_sample_quantity                    -- 24.���{�o��
           ,it_sample_quantity_b        =>  lt_sample_quantity_b                  -- 25.���{�o�ɐU��
           ,it_customer_sample_ship     =>  lt_customer_sample_ship               -- 26.�ڋq���{�o��
           ,it_customer_sample_ship_b   =>  lt_customer_sample_ship_b             -- 27.�ڋq���{�o�ɐU��
           ,it_customer_support_ss      =>  lt_customer_support_ss                -- 28.�ڋq���^���{�o��
           ,it_customer_support_ss_b    =>  lt_customer_support_ss_b              -- 29.�ڋq���^���{�o�ɐU��
           ,it_vd_supplement_stock      =>  lt_vd_supplement_stock                -- 32.����VD��[����
           ,it_vd_supplement_ship       =>  lt_vd_supplement_ship                 -- 33.����VD��[�o��
           ,it_inventory_change_in      =>  lt_inventory_change_in                -- 34.��݌ɕύX����
           ,it_inventory_change_out     =>  lt_inventory_change_out               -- 35.��݌ɕύX�o��
           ,it_factory_return           =>  lt_factory_return                     -- 36.�H��ԕi
           ,it_factory_return_b         =>  lt_factory_return_b                   -- 37.�H��ԕi�U��
           ,it_factory_change           =>  lt_factory_change                     -- 38.�H��q��
           ,it_factory_change_b         =>  lt_factory_change_b                   -- 39.�H��q�֐U��
           ,it_removed_goods            =>  lt_removed_goods                      -- 40.�p�p
           ,it_removed_goods_b          =>  lt_removed_goods_b                    -- 41.�p�p�U��
           ,it_factory_stock            =>  lt_factory_stock                      -- 42.�H�����
           ,it_factory_stock_b          =>  lt_factory_stock_b                    -- 43.�H����ɐU��
           ,it_ccm_sample_ship          =>  lt_ccm_sample_ship                    -- 30.�ڋq�L����`��A���Џ��i
           ,it_ccm_sample_ship_b        =>  lt_ccm_sample_ship_b                  -- 31.�ڋq�L����`��A���Џ��i�U��
           ,it_wear_decrease            =>  lt_wear_decrease                      -- 44.�I�����Ց�
           ,it_wear_increase            =>  lt_wear_increase                      -- 45.�I�����Ռ�
           ,it_selfbase_ship            =>  lt_selfbase_ship                      -- 46.�ۊǏꏊ�ړ��Q�����_�o��
           ,it_selfbase_stock           =>  lt_selfbase_stock                     -- 47.�ۊǏꏊ�ړ��Q�����_����
           ,it_book_inventory_quantity  =>  lt_book_inventory_quantity            -- 48.����݌ɐ�
           ,ib_chk_result               =>  lb_chk_result                         -- 49.�݌ɉ�v����OPEN����
           ,ov_errbuf                   =>  lv_errbuf       --   �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode                  =>  lv_retcode      --   ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg                   =>  lv_errmsg       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          -- �I���p�����[�^����
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
        -- �W�v���ڏ�����
        FOR i IN  1 .. 38 LOOP
          gt_quantity(i)  :=  0;
        END LOOP;
        --
      END IF;
      --
      -- �I������
      EXIT set_material_loop WHEN material_transaction_cur%NOTFOUND;
      --
      -- �󕥏W�v�i����^�C�v�ʁj
      CASE  material_transaction_rec.transaction_type
        WHEN  cv_trans_type_010  THEN   -- 01.����o��
          gt_quantity(1)   :=  gt_quantity(1) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_020  THEN   -- 02.����o�ɐU��
          gt_quantity(2)   :=  gt_quantity(2) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_030  THEN   -- 03.�ԕi
          gt_quantity(3)   :=  gt_quantity(3) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_040  THEN   -- 04.�ԕi�U��
          gt_quantity(4)   :=  gt_quantity(4) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_050  THEN
          IF (    (material_transaction_rec.transaction_qty    < 0)
              AND (material_transaction_rec.inventory_type     = cv_subinv_2)
              AND (material_transaction_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
             )
          THEN
            -- 05.�q�ɂ֕Ԍ�
            gt_quantity(5)   :=  gt_quantity(5) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    < 0)
                 AND (material_transaction_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (material_transaction_rec.subinventory_type  = cv_subinv_2)
                )
          THEN
            -- 06.�c�ƎԂ֏o��
            gt_quantity(6)   :=  gt_quantity(6) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    < 0)
                 AND (material_transaction_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (material_transaction_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                )
          THEN
            -- 07.���o�ɁQ���̑��o��
            gt_quantity(7)   :=  gt_quantity(7) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    > 0)
                 AND (material_transaction_rec.inventory_type     = cv_subinv_2)
                 AND (material_transaction_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                )
          THEN
            -- 08.�q�ɂ�����
            gt_quantity(8)   :=  gt_quantity(8) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    > 0)
                 AND (material_transaction_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (material_transaction_rec.subinventory_type  = cv_subinv_2)
                )
          THEN
            -- 09.�c�ƎԂ�����
            gt_quantity(9)   :=  gt_quantity(9) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    > 0)
                 AND (material_transaction_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (material_transaction_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                )
          THEN
            -- 10.���o�ɁQ���̑�����
            gt_quantity(10)  :=  gt_quantity(10) + material_transaction_rec.transaction_qty;
            --
          END IF;
        WHEN  cv_trans_type_060  THEN
          IF (    (material_transaction_rec.transaction_qty    < 0)
              AND (material_transaction_rec.inventory_type     = cv_subinv_2)
              AND (material_transaction_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
             )
          THEN
            -- 05.�q�ɂ֕Ԍ�
            gt_quantity(5)   :=  gt_quantity(5) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    < 0)
                 AND (material_transaction_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (material_transaction_rec.subinventory_type  = cv_subinv_2)
                )
          THEN
            -- 06.�c�ƎԂ֏o��
            gt_quantity(6)   :=  gt_quantity(6) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    < 0)
                 AND (material_transaction_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (material_transaction_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                )
          THEN
            -- 12.�q�֏o��
            gt_quantity(12)  :=  gt_quantity(12) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    > 0)
                 AND (material_transaction_rec.inventory_type     = cv_subinv_2)
                 AND (material_transaction_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                )
          THEN
            -- 08.�q�ɂ�����
            gt_quantity(8)   :=  gt_quantity(8) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    > 0)
                 AND (material_transaction_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (material_transaction_rec.subinventory_type  = cv_subinv_2)
                )
          THEN
            -- 09.�c�ƎԂ�����
            gt_quantity(9)   :=  gt_quantity(9) + material_transaction_rec.transaction_qty;
          ELSIF (    (material_transaction_rec.transaction_qty    > 0)
                 AND (material_transaction_rec.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (material_transaction_rec.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                )
          THEN
            -- 11.�q�֓���
            gt_quantity(11)  :=  gt_quantity(11) + material_transaction_rec.transaction_qty;
            --
          END IF;
        WHEN  cv_trans_type_070  THEN   -- 13.���i�U�ցi�����i�j
          gt_quantity(13)  :=  gt_quantity(13) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_080  THEN   -- 14.���i�U�ցi�V���i�j
          gt_quantity(14)  :=  gt_quantity(14) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_090  THEN   -- 15.���{�o��
          gt_quantity(15)  :=  gt_quantity(15) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_100 THEN   -- 16.���{�o�ɐU��
          gt_quantity(16)  :=  gt_quantity(16) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_110 THEN   -- 17.�ڋq���{�o��
          gt_quantity(17)  :=  gt_quantity(17) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_120 THEN   -- 18.�ڋq���{�o�ɐU��
          gt_quantity(18)  :=  gt_quantity(18) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_130 THEN   -- 19.�ڋq���^���{�o��
          gt_quantity(19)  :=  gt_quantity(19) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_140 THEN   -- 20.�ڋq���^���{�o�ɐU��
          gt_quantity(20)  :=  gt_quantity(20) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_150 THEN
          IF (material_transaction_rec.transaction_qty >= 0) THEN
            -- 21.����VD��[����
            gt_quantity(21)  :=  gt_quantity(21) + material_transaction_rec.transaction_qty;
          ELSIF (material_transaction_rec.transaction_qty < 0) THEN
            -- 22.����VD��[�o��
            gt_quantity(22)  :=  gt_quantity(22) + material_transaction_rec.transaction_qty;
          END IF;
        WHEN  cv_trans_type_160 THEN
          IF (material_transaction_rec.subinv_class = cv_subinv_class_7)  THEN
            -- ����VD�͑ΏۊO
            NULL;
          ELSIF (material_transaction_rec.transaction_qty   >= 0) THEN
            -- 23.��݌ɕύX����
            gt_quantity(23)  :=  gt_quantity(23) + material_transaction_rec.transaction_qty;
          ELSIF (material_transaction_rec.transaction_qty < 0) THEN
            -- 24.��݌ɕύX�o��
            gt_quantity(24)  :=  gt_quantity(24) + material_transaction_rec.transaction_qty;
          END IF;
        WHEN  cv_trans_type_170 THEN   -- 25.�H��ԕi
          gt_quantity(25)  :=  gt_quantity(25) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_180 THEN   -- 26.�H��ԕi�U��
          gt_quantity(26)  :=  gt_quantity(26) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_190 THEN   -- 27.�H��q��
          gt_quantity(27)  :=  gt_quantity(27) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_200 THEN   -- 28.�H��q�֐U��
          gt_quantity(28)  :=  gt_quantity(28) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_210 THEN   -- 29.�p�p
          gt_quantity(29)  :=  gt_quantity(29) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_220 THEN   -- 30.�p�p�U��
          gt_quantity(30)  :=  gt_quantity(30) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_230 THEN   -- 31.�H�����
          gt_quantity(31)  :=  gt_quantity(31) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_240 THEN   -- 32.�H����ɐU��
          gt_quantity(32)  :=  gt_quantity(32) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_250 THEN   -- 33.�ڋq�L����`��A���Џ��i
          gt_quantity(33)  :=  gt_quantity(33) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_260 THEN   -- 34.�ڋq�L����`��A���Џ��i�U��
          gt_quantity(34)  :=  gt_quantity(34) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_270 THEN   -- 35.�I�����Ց�
          gt_quantity(35)  :=  gt_quantity(35) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_280 THEN   -- 36.�I�����Ռ�
          gt_quantity(36)  :=  gt_quantity(36) + material_transaction_rec.transaction_qty;
        WHEN  cv_trans_type_290 THEN
          IF (material_transaction_rec.transaction_qty < 0) THEN
            -- 37.�ۊǏꏊ�ړ��Q�����_�o��
            gt_quantity(37)  :=  gt_quantity(37) + material_transaction_rec.transaction_qty;
          ELSIF (material_transaction_rec.transaction_qty >= 0) THEN
            -- 38.�ۊǏꏊ�ړ��Q�����_����
            gt_quantity(38)  :=  gt_quantity(38) + material_transaction_rec.transaction_qty;
          END IF;
        ELSE  NULL;
      END CASE;
      --
      -- ���R�[�h�ύX�`�F�b�N�p�ϐ��ێ�
      lt_base_code                :=  material_transaction_rec.base_code;
      lt_subinventory_code        :=  material_transaction_rec.subinventory_code;
      lt_inventory_item_id        :=  material_transaction_rec.inventory_item_id;
      lv_transaction_month        :=  material_transaction_rec.transaction_month;
      lt_transaction_date         :=  material_transaction_rec.transaction_date;
      lt_subinventory_type        :=  material_transaction_rec.inventory_type;
      --
      ln_material_flag    :=  1;
      FETCH material_transaction_cur  INTO  material_transaction_rec;
      --
    END LOOP set_material_loop;
    --
    CLOSE material_transaction_cur;
    --
-- == 2009/10/15 V1.11 Added START ===============================================================
    gn_material_flag    :=  ln_material_flag;
-- == 2009/10/15 V1.11 Added START ===============================================================
    IF (ln_today_data = 0) THEN
      -- ���ގ���i�������j�f�[�^�Ȃ�
      ov_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_short_name
                       ,iv_name         =>  cv_msg_xxcoi1_10128
                      );
      ov_errbuf   :=  ov_errmsg;
      ov_retcode  :=  cv_status_warn;
      gn_warn_cnt :=  gn_warn_cnt + 1;      -- �x�������J�E���g
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
  END set_mtl_transaction_data2;
--
-- == 2009/08/26 V1.8 Added END   ===============================================================
  /**********************************************************************************
   * Procedure Name   : set_last_daily_data
   * Description      : �O��A�g�󕥃f�[�^�o��(A-4, A-5)
   ***********************************************************************************/
  PROCEDURE set_last_daily_data(
    ov_errbuf         OUT VARCHAR2,                     -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode        OUT VARCHAR2,                     -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg         OUT VARCHAR2)                     -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_last_daily_data'; -- �v���O������
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
-- == 2009/08/31 V1.9 Added START ===============================================================
    lt_standard_cost      xxcoi_inv_reception_daily.standard_cost%TYPE;
    lt_operation_cost     xxcoi_inv_reception_daily.operation_cost%TYPE;
-- == 2009/08/31 V1.9 Added START ===============================================================
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
    CURSOR  daily_data_cur
    IS
      SELECT  xird.base_code                          -- ���_�R�[�h
             ,xird.organization_id                    -- �g�DID
             ,xird.subinventory_code                  -- �ۊǏꏊ
             ,xird.practice_date                      -- �N����
             ,xird.inventory_item_id                  -- �i��ID
             ,xird.subinventory_type                  -- �ۊǏꏊ�敪
             ,xird.operation_cost                     -- �c�ƌ���
             ,xird.standard_cost                      -- �W������
             ,xird.book_inventory_quantity            -- ����݌ɐ�
      FROM    xxcoi_inv_reception_daily   xird        -- �O��ŏI�������̓�����
      WHERE   xird.organization_id    =   gn_f_organization_id
      AND     xird.practice_date      =   gd_f_last_cooperation_date;
      --
    -- <�J�[�\����>���R�[�h�^
    daily_data_rec    daily_data_cur%ROWTYPE;
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
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    -- ===============================
    --  ����������f�[�^���f
    -- ===============================
    -- ����������ŁA�ȑO�Ɏ���̂������f�[�^���A�Ɩ��������t�œ������Ƃ��ēo�^
    <<set_last_data_loop>>
    FOR daily_data_rec  IN  daily_data_cur  LOOP
-- == 2009/08/31 V1.9 Added START ===============================================================
      -- ===================================
      --  2.�W�������擾
      -- ===================================
      xxcoi_common_pkg.get_cmpnt_cost(
        in_item_id      =>  daily_data_rec.inventory_item_id                -- �i��ID
       ,in_org_id       =>  gn_f_organization_id                            -- �g�DID
       ,id_period_date  =>  gd_f_business_date                              -- �Ώۓ�
       ,ov_cmpnt_cost   =>  lt_standard_cost                                -- �W������
       ,ov_errbuf       =>  lv_errbuf                                       -- �G���[���b�Z�[�W
       ,ov_retcode      =>  lv_retcode                                      -- ���^�[���E�R�[�h
       ,ov_errmsg       =>  lv_errmsg                                       -- ���[�U�[�E�G���[���b�Z�[�W
      );
      -- �I���p�����[�^����
      IF (lv_retcode = cv_status_error) THEN
        lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_short_name
                        ,iv_name         => cv_msg_xxcoi1_10285
                       );
        lv_errbuf   := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      --
      -- ===================================
      --  2.�c�ƌ����擾
      -- ===================================
      xxcoi_common_pkg.get_discrete_cost(
        in_item_id        =>  daily_data_rec.inventory_item_id                -- �i��ID
       ,in_org_id         =>  gn_f_organization_id                            -- �g�DID
       ,id_target_date    =>  gd_f_business_date                              -- �Ώۓ�
       ,ov_discrete_cost  =>  lt_operation_cost                               -- �c�ƌ���
       ,ov_errbuf         =>  lv_errbuf                                       -- �G���[���b�Z�[�W
       ,ov_retcode        =>  lv_retcode                                      -- ���^�[���E�R�[�h
       ,ov_errmsg         =>  lv_errmsg                                       -- ���[�U�[�E�G���[���b�Z�[�W
      );
      -- �I���p�����[�^����
      IF (lv_retcode = cv_status_error) THEN
        lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_short_name
                        ,iv_name         => cv_msg_xxcoi1_10293
                       );
        lv_errbuf   := lv_errmsg;
        RAISE global_api_expt;
      END IF;
-- == 2009/08/31 V1.9 Added END   ===============================================================
--
      INSERT INTO xxcoi_inv_reception_daily(
            base_code                                        -- 01.���_�R�[�h
           ,organization_id                                  -- 02.�g�DID
           ,subinventory_code                                -- 03.�ۊǏꏊ
           ,practice_date                                    -- 04.�N����
           ,inventory_item_id                                -- 05.�i��ID
           ,subinventory_type                                -- 06.�ۊǏꏊ�敪
           ,operation_cost                                   -- 07.�c�ƌ���
           ,standard_cost                                    -- 08.�W������
           ,previous_inventory_quantity                      -- 09.�O���݌ɐ�
           ,sales_shipped                                    -- 10.����o��
           ,sales_shipped_b                                  -- 11.����o�ɐU��
           ,return_goods                                     -- 12.�ԕi
           ,return_goods_b                                   -- 13.�ԕi�U��
           ,warehouse_ship                                   -- 14.�q�ɂ֕Ԍ�
           ,truck_ship                                       -- 15.�c�ƎԂ֏o��
           ,others_ship                                      -- 16.���o�ɁQ���̑��o��
           ,warehouse_stock                                  -- 17.�q�ɂ�����
           ,truck_stock                                      -- 18.�c�ƎԂ�����
           ,others_stock                                     -- 19.���o�ɁQ���̑�����
           ,change_stock                                     -- 20.�q�֓���
           ,change_ship                                      -- 21.�q�֏o��
           ,goods_transfer_old                               -- 22.���i�U�ցi�����i�j
           ,goods_transfer_new                               -- 23.���i�U�ցi�V���i�j
           ,sample_quantity                                  -- 24.���{�o��
           ,sample_quantity_b                                -- 25.���{�o�ɐU��
           ,customer_sample_ship                             -- 26.�ڋq���{�o��
           ,customer_sample_ship_b                           -- 27.�ڋq���{�o�ɐU��
           ,customer_support_ss                              -- 28.�ڋq���^���{�o��
           ,customer_support_ss_b                            -- 29.�ڋq���^���{�o�ɐU��
           ,vd_supplement_stock                              -- 32.����VD��[����
           ,vd_supplement_ship                               -- 33.����VD��[�o��
           ,inventory_change_in                              -- 34.��݌ɕύX����
           ,inventory_change_out                             -- 35.��݌ɕύX�o��
           ,factory_return                                   -- 36.�H��ԕi
           ,factory_return_b                                 -- 37.�H��ԕi�U��
           ,factory_change                                   -- 38.�H��q��
           ,factory_change_b                                 -- 39.�H��q�֐U��
           ,removed_goods                                    -- 40.�p�p
           ,removed_goods_b                                  -- 41.�p�p�U��
           ,factory_stock                                    -- 42.�H�����
           ,factory_stock_b                                  -- 43.�H����ɐU��
           ,ccm_sample_ship                                  -- 30.�ڋq�L����`��A���Џ��i
           ,ccm_sample_ship_b                                -- 31.�ڋq�L����`��A���Џ��i�U��
           ,wear_decrease                                    -- 44.�I�����Ց�
           ,wear_increase                                    -- 45.�I�����Ռ�
           ,selfbase_ship                                    -- 46.�ۊǏꏊ�ړ��Q�����_�o��
           ,selfbase_stock                                   -- 47.�ۊǏꏊ�ړ��Q�����_����
           ,book_inventory_quantity                          -- 48.����݌ɐ�
           ,last_update_date                                 -- 49.�ŏI�X�V��
           ,last_updated_by                                  -- 50.�ŏI�X�V��
           ,creation_date                                    -- 51.�쐬��
           ,created_by                                       -- 52.�쐬��
           ,last_update_login                                -- 53.�ŏI�X�V���[�U
           ,request_id                                       -- 54.�v��ID
           ,program_application_id                           -- 55.�v���O�����A�v���P�[�V����ID
           ,program_id                                       -- 56.�v���O����ID
           ,program_update_date                              -- 57.�v���O�����X�V��
          )VALUES(
            daily_data_rec.base_code                         -- 01
           ,daily_data_rec.organization_id                   -- 02
           ,daily_data_rec.subinventory_code                 -- 03
           ,gd_f_business_date                               -- 04
           ,daily_data_rec.inventory_item_id                 -- 05
           ,daily_data_rec.subinventory_type                 -- 06
-- == 2009/08/31 V1.9 Modified START ===============================================================
--           ,daily_data_rec.operation_cost
--           ,daily_data_rec.standard_cost
           ,lt_operation_cost                                -- 07
           ,lt_standard_cost                                 -- 08
-- == 2009/08/31 V1.9 Modified END   ===============================================================
           ,daily_data_rec.book_inventory_quantity           -- 09
           ,0                                                -- 10
           ,0                                                -- 11
           ,0                                                -- 12
           ,0                                                -- 13
           ,0                                                -- 14
           ,0                                                -- 15
           ,0                                                -- 16
           ,0                                                -- 17
           ,0                                                -- 18
           ,0                                                -- 19
           ,0                                                -- 20
           ,0                                                -- 21
           ,0                                                -- 22
           ,0                                                -- 23
           ,0                                                -- 24
           ,0                                                -- 25
           ,0                                                -- 26
           ,0                                                -- 27
           ,0                                                -- 28
           ,0                                                -- 29
           ,0                                                -- 32
           ,0                                                -- 33
           ,0                                                -- 34
           ,0                                                -- 35
           ,0                                                -- 36
           ,0                                                -- 37
           ,0                                                -- 38
           ,0                                                -- 39
           ,0                                                -- 40
           ,0                                                -- 41
           ,0                                                -- 42
           ,0                                                -- 43
           ,0                                                -- 30
           ,0                                                -- 31
           ,0                                                -- 44
           ,0                                                -- 45
           ,0                                                -- 46
           ,0                                                -- 47
           ,daily_data_rec.book_inventory_quantity           -- 48
           ,SYSDATE                                          -- 49
           ,cn_last_updated_by                               -- 50
           ,SYSDATE                                          -- 51
           ,cn_created_by                                    -- 52
           ,cn_last_update_login                             -- 53
           ,cn_request_id                                    -- 54
           ,cn_program_application_id                        -- 55
           ,cn_program_id                                    -- 56
           ,SYSDATE                                          -- 57
          );
          --
---- == 2009/08/26 V1.8 Added START ===============================================================
          gn_target_cnt := gn_target_cnt + 1;
---- == 2009/08/26 V1.8 Added END   ===============================================================
    END LOOP set_last_data_loop;
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
  END set_last_daily_data;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
-- == 2009/08/26 V1.8 Added START ===============================================================
    iv_exec_flag    IN VARCHAR2,    --   �N���t���O
    iv_process_date IN VARCHAR2,    --   �Ώۓ��t
-- == 2009/08/26 V1.8 Added END   ===============================================================
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
-- == 2009/08/26 V1.8 Added START ===============================================================
    gv_exec_flag        := iv_exec_flag;
-- == 2009/08/26 V1.8 Added END   ===============================================================
    -- ===================================
    --  1.�N���p�����[�^���O�o��
    -- ===================================
-- == 2009/08/26 V1.8 Modified START ===============================================================
--    -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W
--    gv_out_msg  :=  xxccp_common_pkg.get_msg(
--                      iv_application  =>  cv_short_name
--                     ,iv_name         =>  cv_msg_xxcoi1_00023
--                    );
    -- �N���t���O�F&PROCESS_FLAG
    gv_out_msg  :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_short_name
                     ,iv_name         => cv_msg_xxcoi1_10365
                     ,iv_token_name1  => cv_token_10365_1
                     ,iv_token_value1 => gv_exec_flag
                    );
-- == 2009/08/26 V1.8 Modified END   ===============================================================
    fnd_file.put_line(which       =>  FND_FILE.OUTPUT
                     ,buff        =>  gv_out_msg
    );
-- == 2009/08/26 V1.8 Added START ===============================================================
    IF (iv_process_date IS NOT NULL) THEN
      -- �Ώۓ��t�F&DATE
      gv_out_msg  :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_10401
                       ,iv_token_name1  => cv_token_10401_1
                       ,iv_token_value1 => iv_process_date
                      );
      fnd_file.put_line(which       =>  FND_FILE.OUTPUT
                       ,buff        =>  gv_out_msg
      );
    END IF;
-- == 2009/08/26 V1.8 Added END   ===============================================================
    -- ��s�o��
    fnd_file.put_line(which       =>  FND_FILE.OUTPUT
                     ,buff        =>  cv_space
    );
    --
    -- ===================================
    --  2.�Ɩ��������t�擾
    -- ===================================
-- == 2009/08/26 V1.8 Modified START ===============================================================
    IF (iv_process_date IS NOT NULL) THEN
      IF (TO_DATE(iv_process_date, cv_date_time) >= xxccp_common_pkg2.get_process_date) THEN
        -- �Ɩ����t�̎擾�Ɏ��s���܂����B
        lv_errbuf   :=  xxccp_common_pkg.get_msg(
                          iv_application  => cv_short_name
                         ,iv_name         => cv_msg_xxcoi1_10400
                        );
        lv_errmsg   :=  lv_errbuf;
        RAISE global_process_expt;
      END IF;
      --
      gd_f_business_date  :=  TO_DATE(iv_process_date, cv_date_time);
    ELSE
      gd_f_business_date  :=  xxccp_common_pkg2.get_process_date;
    END IF;
-- == 2009/08/26 V1.8 Modified END   ===============================================================
    --
    IF (gd_f_business_date IS NULL) THEN
      -- �Ɩ����t�̎擾�Ɏ��s���܂����B
      lv_errbuf   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_00011
                      );
      lv_errmsg   :=  lv_errbuf;
      RAISE global_process_expt;
    END IF;
    --
    -- ===================================
    --  3.�݌ɑg�D�R�[�h�擾
    -- ===================================
    gv_f_organization_code  :=  fnd_profile.value(cv_prf_name_orgcd);
    --
    IF (gv_f_organization_code IS NULL) THEN
      -- �v���t�@�C��:�݌ɑg�D�R�[�h( &PRO_TOK )�̎擾�Ɏ��s���܂����B
      lv_errbuf   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_00005
                       ,iv_token_name1  => cv_token_00005_1
                       ,iv_token_value1 => cv_prf_name_orgcd
                      );
      lv_errmsg   :=  lv_errbuf;
      RAISE global_process_expt;
    END IF;
    --
    -- ===================================
    --  4.�݌ɑg�DID�擾
    -- ===================================
    gn_f_organization_id  :=  xxcoi_common_pkg.get_organization_id(gv_f_organization_code);
    --
    IF (gn_f_organization_id IS NULL) THEN
      -- �݌ɑg�D�R�[�h( &ORG_CODE_TOK )�ɑ΂���݌ɑg�DID�̎擾�Ɏ��s���܂����B
      lv_errbuf   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_00006
                       ,iv_token_name1  => cv_token_00006_1
                       ,iv_token_value1 => gv_f_organization_code
                      );
      lv_errmsg   :=  lv_errbuf;
      RAISE global_process_expt;
    END IF;
    --
    -- ===================================
    --  5.WHO�J�����擾
    -- ===================================
    -- �O���[�o���Œ�l�̐ݒ蕔�Ŏ擾���Ă��܂��B
    --
    -- ===================================
    --  6-1.�O��A�g�����ID�擾
    -- ===================================
    BEGIN
      SELECT  xcc.transaction_id                      -- ���ID
             ,TRUNC(xcc.last_cooperation_date)        -- �ŏI�A�g����
      INTO    gn_f_last_transaction_id                -- �����ώ��ID
             ,gd_f_last_cooperation_date              -- ������
      FROM    xxcoi_cooperation_control   xcc         -- �f�[�^�A�g����e�[�u��
-- == 2009/08/26 V1.8 Modified START ===============================================================
--      WHERE   xcc.program_short_name  =   cv_pgsname_a09c;
      WHERE   xcc.program_short_name  =   DECODE(gv_exec_flag, cv_0, cv_pgsname_a09c
                                                                   , cv_pgsname_b09c);
-- == 2009/08/26 V1.8 Modified END   ===============================================================
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �擾�ł��Ȃ������ꍇ�́A���������Ɩ��������t�̑O���A
        -- �����ώ��ID���O�Ƃ��܂��B
        gn_f_last_transaction_id    := 0;
        gd_f_last_cooperation_date  := gd_f_business_date - 1;
    END;
    --
    -- ===================================
    --  6-2.�����ςݔ���
    -- ===================================
    IF (gd_f_last_cooperation_date = gd_f_business_date) THEN
      -- �{�����̏����͊��Ɏ��{�ς݂ł��B
      lv_errbuf   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_10126
                      );
      lv_errmsg   :=  lv_errbuf;
      RAISE global_process_expt;
    END IF;
    --
    -- ===================================
    --  7.���ގ�� �ő���ID�擾
    -- ===================================
    SELECT  MAX(mmt.transaction_id)
    INTO    gn_f_max_transaction_id
    FROM    mtl_material_transactions   mmt
    WHERE   mmt.organization_id   =   gn_f_organization_id
    AND     mmt.transaction_id   >=   gn_f_last_transaction_id;
    --
    IF (gn_f_max_transaction_id IS NULL) THEN
      -- �ő���ID�̎擾�Ɏ��s���܂����B
      lv_errbuf   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_10127
                      );
      lv_errmsg   :=  lv_errbuf;
      RAISE global_process_expt;
    END IF;
    --
    -- ===================================
    --  8.�����f�[�^�ő�N�����擾�i�O���j
    -- ===================================
    SELECT  MAX(xird.practice_date)
    INTO    gd_f_max_practice_date
    FROM    xxcoi_inv_reception_daily   xird
-- == 2009/08/26 V1.8 Modified START ===============================================================
--    WHERE   TO_CHAR(xird.practice_date, cv_month)   =   TO_CHAR(ADD_MONTHS(gd_f_business_date, -1), cv_month);
    WHERE   xird.practice_date  >= TRUNC(LAST_DAY(ADD_MONTHS(gd_f_business_date, -2)) + 1)
    AND     xird.practice_date  <  TRUNC(LAST_DAY(ADD_MONTHS(gd_f_business_date, -1)) + 1)
    ;
-- == 2009/08/26 V1.8 Modified END   ===============================================================
    --
    IF (gd_f_max_practice_date IS NULL) THEN
      gd_f_max_practice_date  :=  LAST_DAY(ADD_MONTHS(gd_f_business_date, -1));
    END IF;
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
-- == 2009/08/26 V1.8 Added START ===============================================================
    iv_exec_flag      IN  VARCHAR2,     -- �N���t���O
    iv_process_date   IN  VARCHAR2,     -- �Ώۓ��t
-- == 2009/08/26 V1.8 Added END   ===============================================================
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
    ln_main_end         NUMBER;
    lv_base_code        VARCHAR2(4);
-- == 2009/05/28 V1.4 Added START ===============================================================
    lt_practice_date    xxcoi_inv_reception_sum.practice_date%TYPE;
-- == 2009/05/28 V1.4 Added END   ===============================================================
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
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    --  �W�v���ڏ�����
    -- ===============================
    FOR i IN  1 .. 38 LOOP
      gt_quantity(i)  :=  0;
    END LOOP;
    --
    -- ===============================
    --  A-1.��������
    -- ===============================
    init(
-- == 2009/08/26 V1.8 Added START ===============================================================
      iv_exec_flag    => iv_exec_flag     -- �N���t���O
     ,iv_process_date => iv_process_date  -- �Ώۓ��t
-- == 2009/08/26 V1.8 Added END   ===============================================================
     ,ov_errbuf     =>  lv_errbuf       --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    =>  lv_retcode      --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     =>  lv_errmsg       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �I���p�����[�^����
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
-- == 2009/08/26 V1.8 Added START ===============================================================
    IF (gv_exec_flag = cv_0) THEN
      --�����N�����̂ݎ��{
-- == 2009/08/26 V1.8 Added END   ===============================================================
      -- ==============================================
      --  A-4, A-5.�O��A�g�󕥃f�[�^�o��
      -- ==============================================
      -- �����݌Ɏ󕥁i�����j
      set_last_daily_data(
        ov_errbuf     =>  lv_errbuf       --   �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    =>  lv_retcode      --   ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     =>  lv_errmsg       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- �I���p�����[�^����
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
      --
-- == 2009/08/26 V1.8 Added START ===============================================================
    END IF;
--
    IF (gv_exec_flag = cv_1) THEN
      --�݌v�N���̂ݎ��{
-- == 2009/08/26 V1.8 Added END   ===============================================================
  -- == 2009/05/28 V1.4 Added START ===============================================================
      -- ==============================================
      --  A-7.�O���T�}�����o��
      -- ==============================================
      BEGIN
        SELECT  MAX(xirs.practice_date)
        INTO    lt_practice_date
        FROM    xxcoi_inv_reception_sum   xirs;
        --
        -- �����̋N���̏ꍇ�ȉ������s
        IF (lt_practice_date = SUBSTRB(TO_CHAR(ADD_MONTHS(gd_f_business_date, -1), cv_date), 1, 6)) THEN
          set_last_daily_sum(
            ov_errbuf     =>  lv_errbuf       --   �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode    =>  lv_retcode      --   ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg     =>  lv_errmsg       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          -- �I���p�����[�^����
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
  -- == 2009/05/28 V1.4 Added END   ===============================================================
-- == 2009/08/26 V1.8 Added START ===============================================================
    END IF;
-- == 2009/08/26 V1.8 Added END   ===============================================================
--
-- == 2009/08/26 V1.8 Adeed START ===============================================================
    IF (gv_exec_flag = cv_0) THEN
      -- �����N���̏ꍇ
-- == 2009/08/26 V1.8 Adeed END   ===============================================================
      -- ==============================================
      --  A-2, A-3.�����f�[�^�����݌Ɏ󕥁i�����j�o��
      -- ==============================================
      set_mtl_transaction_data(
        ov_errbuf     =>  lv_errbuf       --   �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    =>  lv_retcode      --   ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     =>  lv_errmsg       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- �I���p�����[�^����
      IF (lv_retcode = cv_status_error) THEN
        -- �G���[�I��
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_warn) THEN
        -- �x���I��
        ov_errbuf     :=  lv_errbuf;        --  �G���[�E���b�Z�[�W
        ov_retcode    :=  lv_retcode;       --  ���^�[���E�R�[�h
        ov_errmsg     :=  lv_errmsg;        --  ���[�U�[�E�G���[�E���b�Z�[�W
      END IF;
-- == 2009/08/26 V1.8 Adeed START ===============================================================
    ELSIF (gv_exec_flag = cv_1) THEN
      -- �݌v�N���̏ꍇ
      -- ==============================================
      --  A-10, A-11.�����f�[�^�����݌Ɏ󕥁i�݌v�j�o��
      -- ==============================================
      set_mtl_transaction_data2(
        ov_errbuf     =>  lv_errbuf       --   �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    =>  lv_retcode      --   ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     =>  lv_errmsg       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- �I���p�����[�^����
      IF (lv_retcode = cv_status_error) THEN
        -- �G���[�I��
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_warn) THEN
        -- �x���I��
        ov_errbuf     :=  lv_errbuf;        --  �G���[�E���b�Z�[�W
        ov_retcode    :=  lv_retcode;       --  ���^�[���E�R�[�h
        ov_errmsg     :=  lv_errmsg;        --  ���[�U�[�E�G���[�E���b�Z�[�W
      END IF;
    END IF;
-- == 2009/08/26 V1.8 Added END   ===============================================================
    --
-- == 2009/08/26 V1.8 Added START ===============================================================
    IF (gv_exec_flag IN (cv_0, cv_1)) THEN
-- == 2009/08/26 V1.8 Added END   ===============================================================
      -- ==============================================
      --  A-6.�ŏI���ID�X�V
      -- ==============================================
      upd_last_transaction_id(
        ov_errbuf     =>  lv_errbuf       --   �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    =>  lv_retcode      --   ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     =>  lv_errmsg       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- �I���p�����[�^����
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
-- == 2009/08/26 V1.8 Added START ===============================================================
    END IF;
-- == 2009/08/26 V1.8 Added END   ===============================================================
    --
-- == 2009/05/28 V1.4 Deleted START ===============================================================
-- == 2009/04/06 V1.1 Added START ===============================================================
--    -- ==============================================
--    --  A-7, A-8.�݌v�󕥃f�[�^�o��
--    -- ==============================================
--    set_reception_sum(
--      ov_errbuf     =>  lv_errbuf       --   �G���[�E���b�Z�[�W           --# �Œ� #
--     ,ov_retcode    =>  lv_retcode      --   ���^�[���E�R�[�h             --# �Œ� #
--     ,ov_errmsg     =>  lv_errmsg       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--    );
--    -- �I���p�����[�^����
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_process_expt;
--    END IF;
-- == 2009/04/06 V1.1 Added END   ===============================================================
-- == 2009/05/28 V1.4 Deleted END   ===============================================================
    --
-- == 2009/08/26 V1.8 Modified START ===============================================================
--    -- ==============================================
--    --  A-9.�I������
--    -- ==============================================
--    finalize(
--      ov_errbuf     =>  lv_errbuf       --   �G���[�E���b�Z�[�W           --# �Œ� #
--     ,ov_retcode    =>  lv_retcode      --   ���^�[���E�R�[�h             --# �Œ� #
--     ,ov_errmsg     =>  lv_errmsg       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--    );
--    -- �I���p�����[�^����
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_process_expt;
--    END IF;
    -- �Ώی����𐬌�������
    gn_normal_cnt := gn_target_cnt;
-- == 2009/08/26 V1.8 Modified END   ===============================================================
    --
  EXCEPTION
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- ��������
      gn_error_cnt  :=  gn_error_cnt + 1;
      gn_normal_cnt :=  0;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- ��������
      gn_error_cnt  :=  gn_error_cnt + 1;
      gn_normal_cnt :=  0;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- ��������
      gn_error_cnt  :=  gn_error_cnt + 1;
      gn_normal_cnt :=  0;
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
    errbuf              OUT VARCHAR2,       -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode             OUT VARCHAR2,       -- ���^�[���E�R�[�h    --# �Œ� #
-- == 2009/08/26 V1.8 Added START ===============================================================
    iv_exec_flag        IN  VARCHAR2,       -- �N���t���O
    iv_process_date     IN  VARCHAR2        -- �Ώۓ��t
-- == 2009/08/26 V1.8 Added END   ===============================================================
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
-- == 2009/08/26 V1.8 Added START ===============================================================
        iv_exec_flag        =>  iv_exec_flag        -- �N���t���O
       ,iv_process_date     =>  iv_process_date     -- �Ώۓ��t
-- == 2009/08/26 V1.8 Added END   ===============================================================
       ,ov_errbuf           =>  lv_errbuf           -- �G���[�E���b�Z�[�W             --# �Œ� #
       ,ov_retcode          =>  lv_retcode          -- ���^�[���E�R�[�h               --# �Œ� #
       ,ov_errmsg           =>  lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
    );
--
    IF (lv_retcode <> cv_status_normal) THEN
      --�G���[�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      -- ��s���o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => cv_space
      );
-- == 2009/10/15 V1.11 Modified START ===============================================================
---- == 2009/09/16 V1.10 Added START ===============================================================
--      gn_target_cnt :=  0;
--      gn_normal_cnt :=  0;
---- == 2009/09/16 V1.10 Added END   ===============================================================
      IF (lv_retcode = cv_status_warn AND gn_material_flag = 0) THEN
        gn_target_cnt :=  0;
        gn_normal_cnt :=  0;
      END IF;
-- == 2009/10/15 V1.11 Modified END   ===============================================================
    END IF;
    --
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- ��s���o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
-- == 2009/10/15 V1.11 Modified START ===============================================================
-- == 2009/09/16 V1.10 Modified START ===============================================================
--    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
--    IF (retcode = cv_status_error) THEN
--      ROLLBACK;
--    END IF;
--    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
--    IF (retcode <> cv_status_normal) THEN
--      ROLLBACK;
--    END IF;
-- == 2009/09/16 V1.10 Modified END   ===============================================================
    -- �I���X�e�[�^�X���G���[�̏ꍇ
    -- �܂��́A�Ώۂ̎��ގ���f�[�^�����݂��Ȃ��ꍇ��ROLLBACK����
    IF (retcode = cv_status_error OR gn_material_flag = 0)  THEN
      ROLLBACK;
    END IF;
-- == 2009/10/15 V1.11 Modified END   ===============================================================
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
END XXCOI006A09C;
/
