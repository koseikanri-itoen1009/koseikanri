CREATE OR REPLACE PACKAGE BODY XXCOI010A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI010A03C(body)
 * Description      : VD�R�����}�X�^HHT�A�g
 * MD.050           : VD�R�����}�X�^HHT�A�g MD050_COI_010_A03
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   �������� (A-1)
 *  get_last_coop_date     �f�[�^�A�g���䃏�[�N�e�[�u���̍ŏI�A�g�����擾 (A-2)
 *  get_mst_vd_column      VD�R�����}�X�^��񒊏o (A-4)
 *  create_csv_file        �x���_�݌Ƀ}�X�^CSV�쐬 (A-5)
 *  upd_last_coop_date     �f�[�^�A�g���䃏�[�N�e�[�u���̍ŏI�A�g�����X�V (A-6)
 *  submain                ���C�������v���V�[�W��
 *                         UTL�t�@�C���I�[�v�� (A-3)
 *                         UTL�t�@�C���N���[�Y (A-7)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/02    1.0   T.Nakamura       �V�K�쐬
 *  2009/09/14    1.1   H.Sasaki         [0001348]PT�Ή�
 *  2009/11/23    1.2   T.Kojima         [E_�{�ғ�_00006]��R����IF
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
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
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCOI010A03C';     -- �p�b�P�[�W��
  cv_appl_short_name_xxccp    CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�v���P�[�V�����Z�k���FXXCCP
  cv_appl_short_name_xxcoi    CONSTANT VARCHAR2(10)  := 'XXCOI';            -- �A�v���P�[�V�����Z�k���FXXCOI
--
  -- ���b�Z�[�W
  cv_para_night_exec_f_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10315'; -- �p�����[�^�F��Ԏ��s�t���O
  cv_file_name_msg            CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00028'; -- �t�@�C�����o�̓��b�Z�[�W
  cv_no_data_msg              CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00008'; -- �Ώۃf�[�^�Ȃ����b�Z�[�W
  cv_cal_code_get_err_msg     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10297'; -- �J�����_�[�R�[�h�擾�G���[���b�Z�[�W
  cv_proc_date_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00011'; -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_next_sys_act_get_err_msg CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10298'; -- ���V�X�e���ғ����擾�G���[���b�Z�[�W
  cv_dire_name_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00003'; -- �f�B���N�g�����擾�G���[���b�Z�[�W
  cv_dire_path_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00029'; -- �f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
  cv_file_name_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00004'; -- �t�@�C�����擾�G���[���b�Z�[�W
  cv_last_coop_d_get_err_msg  CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10010'; -- �ŏI�A�g�����擾�G���[���b�Z�[�W
  cv_table_lock_err_msg       CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10001'; -- ���b�N�擾�G���[���b�Z�[�W
  cv_file_remain_err_msg      CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00027'; -- �t�@�C�����݃`�F�b�N�G���[���b�Z�[�W
  -- �g�[�N��
  cv_tkn_p_flag               CONSTANT VARCHAR2(20)  := 'P_FLAG';           -- ��Ԏ��s�t���O
  cv_tkn_program_id           CONSTANT VARCHAR2(20)  := 'PROGRAM_ID';       -- �v���O����ID
  cv_tkn_pro_tok              CONSTANT VARCHAR2(20)  := 'PRO_TOK';          -- �v���t�@�C����
  cv_tkn_file_name            CONSTANT VARCHAR2(20)  := 'FILE_NAME';        -- �t�@�C����
  cv_tkn_dir_tok              CONSTANT VARCHAR2(20)  := 'DIR_TOK';          -- �f�B���N�g����
--
  cv_night_exec_flag_y        CONSTANT VARCHAR2(1)   := 'Y';                -- ��Ԏ��s�t���O�F'Y'
  cv_night_exec_flag_n        CONSTANT VARCHAR2(1)   := 'N';                -- ��Ԏ��s�t���O�F'N'
  cv_cust_status_reorg_crd    CONSTANT VARCHAR2(2)   := '80';               -- �ڋq�X�e�[�^�X�F�X����
  cv_cust_status_stop_apr     CONSTANT VARCHAR2(2)   := '90';               -- �ڋq�X�e�[�^�X�F���~���ٍ�
  cv_del_flag_y               CONSTANT VARCHAR2(1)   := '1';                -- �폜�t���O�F'1'
  cv_del_flag_n               CONSTANT VARCHAR2(1)   := '0';                -- �폜�t���O�F'0'
-- == 2009/11/23 V1.2 ADD START  ===============================================================
  cn_price_dummy              CONSTANT NUMBER        := 0;                  -- ���i�_�~�[
  cv_hot_cold_dummy           CONSTANT VARCHAR2(1)   := '0';                -- H/C�_�~�[
  cv_item_code_dummy          CONSTANT VARCHAR2(7)   := '0000000';          -- �i�ڃR�[�h�_�~�[
-- == 2009/11/23 V1.2 ADD END    ===============================================================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_night_exec_flag   VARCHAR2(1);           -- ��Ԏ��s�t���O
  gd_sysdate           DATE;                  -- SYSDATE
  gd_process_date      DATE;                  -- �Ɩ����t
  gd_next_sys_act_day  DATE;                  -- ���V�X�e���ғ���
  gd_last_coop_date    DATE;                  -- �ŏI�A�g����
  gv_dire_name         VARCHAR2(50);          -- �f�B���N�g����
  gv_file_name         VARCHAR2(50);          -- �t�@�C����
  g_file_handle        UTL_FILE.FILE_TYPE;    -- �t�@�C���n���h��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  -- VD�R�����}�X�^��񒊏o
-- == 2009/09/14 V1.1 Modified START ===============================================================
--  CURSOR get_xmvc_tbl_cur
--  IS
--    -- �ŏI�A�g�����ȍ~�ASYSDATE���O�ɍX�V���ꂽVD�R�����}�X�^�̃f�[�^�𒊏o
--    SELECT   xmvc.column_no                AS column_no                   -- �R����NO.
--           , xmvc.price                    AS price                       -- �P��
--           , xmvc.inventory_quantity       AS inventory_quantity          -- ���^����
--           , xmvc.hot_cold                 AS hot_cold                    -- H/C
--           , xmvc.last_update_date         AS last_update_date            -- �X�V����
--           , msib.segment1                 AS item_code                   -- �i�ڃR�[�h
--           , hca.account_number            AS cust_code                   -- �ڋq�R�[�h
--           , CASE WHEN hp.duns_number_c IN ( cv_cust_status_reorg_crd     -- �ڋq�X�e�[�^�X���u�X�����v
--                                           , cv_cust_status_stop_apr )    -- �܂��́A�u���~���ٍρv�̏ꍇ
--                  THEN cv_del_flag_y                                      -- �폜�t���O��'1'��ݒ�
--                  ELSE cv_del_flag_n                                      -- ����ȊO�̏ꍇ�A�폜�t���O��'0'��ݒ�
--             END                           AS del_flag                    -- �폜�t���O
--    FROM     xxcoi_mst_vd_column           xmvc                           -- VD�R�����}�X�^
--           , mtl_system_items_b            msib                           -- �i�ڃ}�X�^
--           , hz_cust_accounts              hca                            -- �ڋq�}�X�^
--           , hz_parties                    hp                             -- �p�[�e�B
--    WHERE    xmvc.last_update_date         >= gd_last_coop_date           -- �擾�����F�ŏI�X�V�����ŏI�A�g�����ȍ~
--    AND      xmvc.last_update_date         <  gd_sysdate                  -- �擾�����F�ŏI�X�V����SYSDATE���O
--    AND      msib.inventory_item_id        =  xmvc.item_id                -- ���������F�i�ڃ}�X�^��VD�R�����}�X�^
--    AND      msib.organization_id          =  xmvc.organization_id        -- ���������F�i�ڃ}�X�^��VD�R�����}�X�^
--    AND      hca.cust_account_id           =  xmvc.customer_id            -- ���������F�ڋq�}�X�^��VD�R�����}�X�^
--    AND      hp.party_id                   =  hca.party_id                -- ���������F�p�[�e�B�ƌڋq�}�X�^
--    UNION                                                                 -- �}�[�W
--    -- �ڋq�ڍs�����O��ŏI�A�g�������傫���A�Ɩ����t�ȑO�̌ڋq�ڍs���𒊏o
--    SELECT   xmvc.column_no                AS column_no                   -- �R����NO.
--           , xmvc.price                    AS price                       -- �P��
--           , xmvc.inventory_quantity       AS inventory_quantity          -- ���^����
--           , xmvc.hot_cold                 AS hot_cold                    -- H/C
--           , xmvc.last_update_date         AS last_update_date            -- �X�V����
--           , msib.segment1                 AS item_code                   -- �i�ڃR�[�h
--           , hca.account_number            AS cust_code                   -- �ڋq�R�[�h
--           , CASE WHEN hp.duns_number_c IN ( cv_cust_status_reorg_crd     -- �ڋq�X�e�[�^�X���u�X�����v
--                                           , cv_cust_status_stop_apr )    -- �܂��́A�u���~���ٍρv�̏ꍇ
--                  THEN cv_del_flag_y                                      -- �폜�t���O��'1'��ݒ�
--                  ELSE cv_del_flag_n                                      -- ����ȊO�̏ꍇ�A�폜�t���O��'0'��ݒ�
--             END                           AS del_flag                    -- �폜�t���O
--    FROM     xxcoi_mst_vd_column           xmvc                           -- VD�R�����}�X�^
--           , mtl_system_items_b            msib                           -- �i�ڃ}�X�^
--           , hz_cust_accounts              hca                            -- �ڋq�}�X�^
--           , xxcok_cust_shift_info         xcsi                           -- �ڋq�ڍs���
--           , hz_parties                    hp                             -- �p�[�e�B
--    WHERE    xmvc.last_update_date         <  gd_last_coop_date           -- �擾�����F�ŏI�X�V�����ŏI�A�g�������O
--    AND      msib.inventory_item_id        =  xmvc.item_id                -- ���������F�i�ڃ}�X�^��VD�R�����}�X�^
--    AND      msib.organization_id          =  xmvc.organization_id        -- ���������F�i�ڃ}�X�^��VD�R�����}�X�^
--    AND      hca.cust_account_id           =  xmvc.customer_id            -- ���������F�ڋq�}�X�^��VD�R�����}�X�^
--    AND      xcsi.cust_code                =  hca.account_number          -- ���������F�ڋq�ڍs���ƌڋq�}�X�^
--    AND      xcsi.cust_shift_date          >= TRUNC( gd_last_coop_date )  -- �擾�����F�ڋq�ڍs�����ŏI�A�g�����t�ȍ~
--    AND      xcsi.cust_shift_date          <=                             -- �擾�����F�ڋq�ڍs���́A
--               CASE WHEN gv_night_exec_flag     =  cv_night_exec_flag_y   -- ��Ԏ��s�t���O��'Y'�̏ꍇ�A
--                    THEN gd_next_sys_act_day                              -- ���V�X�e���ғ����ȑO
--                    ELSE gd_process_date                                  -- ����ȊO�̏ꍇ�A�Ɩ����t�ȑO
--               END
--    AND      hp.party_id                   =  hca.party_id                -- ���������F�p�[�e�B�ƌڋq�}�X�^
--  ;
--
  CURSOR  get_xmvc_tbl_cur1
  IS
    SELECT   /*+ use_nl(hp hca xmvc msib) */
             xmvc.column_no                AS column_no                   -- �R����NO.
-- == 2009/11/23 V1.2 MOD START  ===============================================================
--         , xmvc.price                    AS price                       -- �P��
           , NVL( xmvc.price, cn_price_dummy )          AS price          -- �P��
-- == 2009/11/23 V1.2 MOD END    ===============================================================
           , xmvc.inventory_quantity       AS inventory_quantity          -- ���^����
-- == 2009/11/23 V1.2 MOD START  ===============================================================
--         , xmvc.hot_cold                 AS hot_cold                    -- H/C
           , NVL( xmvc.hot_cold, cv_hot_cold_dummy )    AS hot_cold       -- H/C
-- == 2009/11/23 V1.2 MOD END    ===============================================================
           , xmvc.last_update_date         AS last_update_date            -- �X�V����
-- == 2009/11/23 V1.2 MOD START  ===============================================================
--         , msib.segment1                 AS item_code                   -- �i�ڃR�[�h
           , NVL( msib.segment1, cv_item_code_dummy )   AS item_code      -- �i�ڃR�[�h
-- == 2009/11/23 V1.2 MOD END    ===============================================================
           , hca.account_number            AS cust_code                   -- �ڋq�R�[�h
           , CASE WHEN hp.duns_number_c IN ( cv_cust_status_reorg_crd     -- �ڋq�X�e�[�^�X���u�X�����v
                                           , cv_cust_status_stop_apr )    -- �܂��́A�u���~���ٍρv�̏ꍇ
                  THEN cv_del_flag_y                                      -- �폜�t���O��'1'��ݒ�
                  ELSE cv_del_flag_n                                      -- ����ȊO�̏ꍇ�A�폜�t���O��'0'��ݒ�
             END                           AS del_flag                    -- �폜�t���O
    FROM     xxcoi_mst_vd_column           xmvc                           -- VD�R�����}�X�^
           , mtl_system_items_b            msib                           -- �i�ڃ}�X�^
           , hz_cust_accounts              hca                            -- �ڋq�}�X�^
           , hz_parties                    hp                             -- �p�[�e�B
    WHERE    xmvc.last_update_date         >= gd_last_coop_date           -- �擾�����F�ŏI�X�V�����ŏI�A�g�����ȍ~
    AND      xmvc.last_update_date         <  gd_sysdate                  -- �擾�����F�ŏI�X�V����SYSDATE���O
-- == 2009/11/23 V1.2 MOD START  ===============================================================
--  AND      msib.inventory_item_id        =  xmvc.item_id                -- ���������F�i�ڃ}�X�^��VD�R�����}�X�^
--  AND      msib.organization_id          =  xmvc.organization_id        -- ���������F�i�ڃ}�X�^��VD�R�����}�X�^
    AND      msib.inventory_item_id (+)    =  xmvc.item_id                -- ���������F�i�ڃ}�X�^��VD�R�����}�X�^
    AND      msib.organization_id   (+)    =  xmvc.organization_id        -- ���������F�i�ڃ}�X�^��VD�R�����}�X�^
-- == 2009/11/23 V1.2 MOD END    ===============================================================
    AND      hca.cust_account_id           =  xmvc.customer_id            -- ���������F�ڋq�}�X�^��VD�R�����}�X�^
    AND      hp.party_id                   =  hca.party_id;               -- ���������F�p�[�e�B�ƌڋq�}�X�^
  --
  CURSOR  get_xmvc_tbl_cur2
  IS
    SELECT   /*+ use_nl(hp hca xcsi xmvc msib) */
             xmvc.column_no                AS column_no                   -- �R����NO.
-- == 2009/11/23 V1.2 MOD START  ===============================================================
--         , xmvc.price                    AS price                       -- �P��
           , NVL( xmvc.price, cn_price_dummy )          AS price          -- �P��
-- == 2009/11/23 V1.2 MOD END    ===============================================================
           , xmvc.inventory_quantity       AS inventory_quantity          -- ���^����
-- == 2009/11/23 V1.2 MOD START  ===============================================================
--         , xmvc.hot_cold                 AS hot_cold                    -- H/C
           , NVL( xmvc.hot_cold, cv_hot_cold_dummy )    AS hot_cold       -- H/C
-- == 2009/11/23 V1.2 MOD END    ===============================================================
           , xmvc.last_update_date         AS last_update_date            -- �X�V����
-- == 2009/11/23 V1.2 MOD START  ===============================================================
--         , msib.segment1                 AS item_code                   -- �i�ڃR�[�h
           , NVL( msib.segment1, cv_item_code_dummy )   AS item_code      -- �i�ڃR�[�h
-- == 2009/11/23 V1.2 MOD END    ===============================================================
           , hca.account_number            AS cust_code                   -- �ڋq�R�[�h
           , CASE WHEN hp.duns_number_c IN ( cv_cust_status_reorg_crd     -- �ڋq�X�e�[�^�X���u�X�����v
                                           , cv_cust_status_stop_apr )    -- �܂��́A�u���~���ٍρv�̏ꍇ
                  THEN cv_del_flag_y                                      -- �폜�t���O��'1'��ݒ�
                  ELSE cv_del_flag_n                                      -- ����ȊO�̏ꍇ�A�폜�t���O��'0'��ݒ�
             END                           AS del_flag                    -- �폜�t���O
    FROM     xxcoi_mst_vd_column           xmvc                           -- VD�R�����}�X�^
           , mtl_system_items_b            msib                           -- �i�ڃ}�X�^
           , hz_cust_accounts              hca                            -- �ڋq�}�X�^
           , xxcok_cust_shift_info         xcsi                           -- �ڋq�ڍs���
           , hz_parties                    hp                             -- �p�[�e�B
    WHERE    xmvc.last_update_date         <  gd_last_coop_date           -- �擾�����F�ŏI�X�V�����ŏI�A�g�������O
-- == 2009/11/23 V1.2 MOD START  ===============================================================
--  AND      msib.inventory_item_id        =  xmvc.item_id                -- ���������F�i�ڃ}�X�^��VD�R�����}�X�^
--  AND      msib.organization_id          =  xmvc.organization_id        -- ���������F�i�ڃ}�X�^��VD�R�����}�X�^
    AND      msib.inventory_item_id (+)    =  xmvc.item_id                -- ���������F�i�ڃ}�X�^��VD�R�����}�X�^
    AND      msib.organization_id   (+)    =  xmvc.organization_id        -- ���������F�i�ڃ}�X�^��VD�R�����}�X�^
-- == 2009/11/23 V1.2 MOD END    ===============================================================
    AND      hca.cust_account_id           =  xmvc.customer_id            -- ���������F�ڋq�}�X�^��VD�R�����}�X�^
    AND      xcsi.cust_code                =  hca.account_number          -- ���������F�ڋq�ڍs���ƌڋq�}�X�^
    AND      xcsi.cust_shift_date          >= TRUNC( gd_last_coop_date )  -- �擾�����F�ڋq�ڍs�����ŏI�A�g�����t�ȍ~
    AND      xcsi.cust_shift_date          <=                             -- �擾�����F�ڋq�ڍs���́A
               CASE WHEN gv_night_exec_flag     =  cv_night_exec_flag_y   -- ��Ԏ��s�t���O��'Y'�̏ꍇ�A
                    THEN gd_next_sys_act_day                              -- ���V�X�e���ғ����ȑO
                    ELSE gd_process_date                                  -- ����ȊO�̏ꍇ�A�Ɩ����t�ȑO
               END
    AND      hp.party_id                   =  hca.party_id;               -- ���������F�p�[�e�B�ƌڋq�}�X�^
-- == 2009/09/14 V1.1 Modified END   ===============================================================
--
  -- ==============================
  -- ���[�U�[��`�O���[�o���e�[�u��
  -- ==============================
-- == 2009/09/14 V1.1 Modified START ===============================================================
--  TYPE g_get_xmvc_tbl_ttype IS TABLE OF get_xmvc_tbl_cur%ROWTYPE INDEX BY BINARY_INTEGER;
--  g_get_xmvc_tbl_tab        g_get_xmvc_tbl_ttype;
  get_xmvc_tbl_rec  get_xmvc_tbl_cur1%ROWTYPE;
-- == 2009/09/14 V1.1 Modified END   ===============================================================
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  get_last_coop_date_expt   EXCEPTION;     -- �ŏI�A�g�����擾�G���[
  lock_expt                 EXCEPTION;     -- ���b�N�擾�G���[
  remain_file_expt          EXCEPTION;     -- �t�@�C�����݃G���[
--
  PRAGMA EXCEPTION_INIT( lock_expt, -54 ); -- ���b�N�擾��O
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- �v���t�@�C�� XXCOI:�V�X�e���ғ����J�����_�[�R�[�h
    cv_prf_sys_act_cal_code    CONSTANT VARCHAR2(30) := 'XXCOI1_SYS_ACT_CALENDAR_CODE';
    -- �v���t�@�C�� XXCOI:HHT_OUTBOUND�i�[�f�B���N�g���p�X
    cv_prf_dire_out_hht        CONSTANT VARCHAR2(30) := 'XXCOI1_DIRE_OUT_HHT';
    -- �v���t�@�C�� XXCOI:VD�R�����}�X�^HHT�A�g�t�@�C����
    cv_prf_file_vdhht          CONSTANT VARCHAR2(30) := 'XXCOI1_FILE_VDHHT';
--
    cn_working_day             CONSTANT NUMBER       := 1;    -- �c�Ɠ���
    cv_slash                   CONSTANT VARCHAR2(1)  := '/';  -- �X���b�V��
--
    -- *** ���[�J���ϐ� ***
    lv_sys_act_cal_code        VARCHAR2(50);                  -- �V�X�e���ғ����J�����_�[�R�[�h
    lv_dire_path               VARCHAR2(100);                 -- �f�B���N�g���t���p�X�i�[�ϐ�
    lv_file_name               VARCHAR2(100);                 -- �t�@�C�����i�[�ϐ�
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
    -- ===============================
    -- �R���J�����g���̓p�����[�^�o��
    -- ===============================
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxcoi
                    , iv_name         => cv_para_night_exec_f_msg
                    , iv_token_name1  => cv_tkn_p_flag
                    , iv_token_value1 => gv_night_exec_flag
                  );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => gv_out_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => ''
    );
--
    -- ===============================
    -- SYSDATE�擾
    -- ===============================
    gd_sysdate := SYSDATE;
--
    -- ==============================================================
    -- �v���t�@�C���F�V�X�e���ғ����J�����_�[�R�[�h�擾
    -- ==============================================================
    lv_sys_act_cal_code := fnd_profile.value( cv_prf_sys_act_cal_code );
    -- �V�X�e���ғ����J�����_�[�R�[�h���擾�ł��Ȃ��ꍇ
    IF ( lv_sys_act_cal_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_cal_code_get_err_msg
                     , iv_token_name1  => cv_tkn_pro_tok
                     , iv_token_value1 => cv_prf_sys_act_cal_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �Ɩ����t�擾
    -- ===============================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- �Ɩ����t���擾�ł��Ȃ��ꍇ
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_proc_date_get_err_msg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ���V�X�e���ғ����擾
    -- ===============================
    gd_next_sys_act_day := xxccp_common_pkg2.get_working_day(
                               id_date          => gd_process_date
                             , in_working_day   => cn_working_day
                             , iv_calendar_code => lv_sys_act_cal_code
                           );
    -- ���V�X�e���ғ������擾�ł��Ȃ��ꍇ
    IF ( gd_next_sys_act_day IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_next_sys_act_get_err_msg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �v���t�@�C���F�f�B���N�g�����擾
    -- ===============================
    -- �f�B���N�g�����擾
    gv_dire_name := fnd_profile.value( cv_prf_dire_out_hht );
    -- �f�B���N�g�������擾�ł��Ȃ��ꍇ
    IF ( gv_dire_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_dire_name_get_err_msg
                     , iv_token_name1  => cv_tkn_pro_tok
                     , iv_token_value1 => cv_prf_dire_out_hht
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �f�B���N�g���p�X�擾
    BEGIN
      SELECT directory_path
      INTO   lv_dire_path
      FROM   all_directories
      WHERE  directory_name    = gv_dire_name;
    EXCEPTION
      -- �f�B���N�g���p�X���擾�ł��Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name_xxcoi
                         , iv_name         => cv_dire_path_get_err_msg
                         , iv_token_name1  => cv_tkn_dir_tok
                         , iv_token_value1 => gv_dire_name
                       );
        lv_errbuf   := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- ===============================
    -- �v���t�@�C���F�t�@�C�����擾
    -- ===============================
    gv_file_name := fnd_profile.value( cv_prf_file_vdhht );
    -- �t�@�C�������擾�ł��Ȃ��ꍇ
    IF ( gv_file_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_file_name_get_err_msg
                     , iv_token_name1  => cv_tkn_pro_tok
                     , iv_token_value1 => cv_prf_file_vdhht
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ==============================================================
    -- IF�t�@�C�����iIF�t�@�C���̃t���p�X���j�o��
    -- ==============================================================
    lv_file_name := lv_dire_path || cv_slash || gv_file_name;
    gv_out_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcoi
                      , iv_name         => cv_file_name_msg
                      , iv_token_name1  => cv_tkn_file_name
                      , iv_token_value1 => lv_file_name
                    );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN
    -- *** ���ʊ֐���O�n���h�� ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
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
   * Procedure Name   : get_last_coop_date
   * Description      : �f�[�^�A�g���䃏�[�N�e�[�u���̍ŏI�A�g�����擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_last_coop_date(
      ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_last_coop_date'; -- �v���O������
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
    -- ==============================================================
    -- �f�[�^�A�g���䃏�[�N�e�[�u������O��̍ŏI�A�g�����A���b�N���擾
    -- ==============================================================
    BEGIN
--
      SELECT xcc.last_cooperation_date AS last_cooperation_date -- �ŏI�A�g����
      INTO   gd_last_coop_date
      FROM   xxcoi_cooperation_control xcc                      -- �f�[�^�A�g���䃏�[�N�e�[�u��
      WHERE  xcc.program_id            = cn_program_id          -- �擾�����v���O����ID
      FOR UPDATE NOWAIT;                                        -- ���b�N�擾
--
    -- �O��̍ŏI�A�g�������擾�ł��Ȃ��ꍇ
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE get_last_coop_date_expt;
--
      WHEN OTHERS THEN
        RAISE;
--
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- �ŏI�A�g�����擾�G���[
    WHEN get_last_coop_date_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcoi
                      , iv_name         => cv_last_coop_d_get_err_msg
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
--
    -- ���b�N�擾�G���[
    WHEN lock_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcoi
                      , iv_name         => cv_table_lock_err_msg
                      , iv_token_name1  => cv_tkn_program_id
                      , iv_token_value1 => cn_program_id
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
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
  END get_last_coop_date;
--
-- == 2009/09/14 V1.1 Deleted START ===============================================================
--  /**********************************************************************************
--   * Procedure Name   : get_mst_vd_column
--   * Description      : VD�R�����}�X�^��񒊏o(A-4)
--   ***********************************************************************************/
--  PROCEDURE get_mst_vd_column(
--      ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
--    , ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
--    , ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--  IS
--    -- ===============================
--    -- �Œ胍�[�J���萔
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_mst_vd_column'; -- �v���O������
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
--    -- *** ���[�J���E�J�[�\�� ***
----
--    -- *** ���[�J���E���R�[�h ***
----
--  BEGIN
----
----##################  �Œ�X�e�[�^�X�������� START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  �Œ蕔 END   ############################
----
--    -- �J�[�\���I�[�v��
--    OPEN  get_xmvc_tbl_cur;
----
--    -- �J�[�\���f�[�^�擾
--    FETCH get_xmvc_tbl_cur BULK COLLECT INTO g_get_xmvc_tbl_tab;
----
--    -- �J�[�\���̃N���[�Y
--    CLOSE get_xmvc_tbl_cur;
----
--    -- ===============================
--    -- �Ώی����J�E���g
--    -- ===============================
--    gn_target_cnt := g_get_xmvc_tbl_tab.COUNT;
----
--    -- ===============================
--    -- ���o0���`�F�b�N
--    -- ===============================
--    IF ( gn_target_cnt = 0 ) THEN
--      gv_out_msg := xxccp_common_pkg.get_msg(
--                        iv_application  => cv_appl_short_name_xxcoi
--                      , iv_name         => cv_no_data_msg
--                    );
--      -- ���b�Z�[�W�o��
--      FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--        , buff   => gv_out_msg
--      );
--    END IF;
----
--    --==============================================================
--    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
--    --==============================================================
----
--  EXCEPTION
----
----#################################  �Œ��O������ START   ####################################
----
--    -- *** ���ʊ֐���O�n���h�� ***
--    WHEN global_api_expt THEN
--      -- �J�[�\����OPEN���Ă���ꍇ
--      IF ( get_xmvc_tbl_cur%ISOPEN ) THEN
--        CLOSE get_xmvc_tbl_cur;
--      END IF;
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--    WHEN global_api_others_expt THEN
--      -- �J�[�\����OPEN���Ă���ꍇ
--      IF ( get_xmvc_tbl_cur%ISOPEN ) THEN
--        CLOSE get_xmvc_tbl_cur;
--      END IF;
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--    -- *** OTHERS��O�n���h�� ***
--    WHEN OTHERS THEN
--      -- �J�[�\����OPEN���Ă���ꍇ
--      IF ( get_xmvc_tbl_cur%ISOPEN ) THEN
--        CLOSE get_xmvc_tbl_cur;
--      END IF;
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
----
----#####################################  �Œ蕔 END   ##########################################
----
--  END get_mst_vd_column;
-- == 2009/09/14 V1.1 Deleted END   ===============================================================
--
  /**********************************************************************************
   * Procedure Name   : create_csv_file
   * Description      : �x���_�݌Ƀ}�X�^CSV�쐬(A-5)
   ***********************************************************************************/
  PROCEDURE create_csv_file(
      ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_csv_file'; -- �v���O������
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
    cv_delimiter             CONSTANT VARCHAR2(1) := ',';  -- ��؂蕶��
    cv_encloser              CONSTANT VARCHAR2(1) := '"';  -- ���蕶��
--
    -- *** ���[�J���ϐ� ***
    lv_csv_file              VARCHAR2(1500);               -- CSV�t�@�C��
    lv_column_no             VARCHAR2(100);                -- �R����NO.
    lv_price                 VARCHAR2(100);                -- �P��
    lv_inventory_quantity    VARCHAR2(100);                -- ���^����
    lv_last_update_date      VARCHAR2(100);                -- �ŏI�X�V��
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
    -- ===============================
    -- ���[�v�J�n
    -- ===============================
-- == 2009/09/14 V1.1 Modified START ===============================================================
--    <<create_file_loop>>
--    FOR i IN 1 .. g_get_xmvc_tbl_tab.COUNT LOOP
--      lv_column_no          := TO_CHAR( g_get_xmvc_tbl_tab(i).column_no );                                -- �R����No.
--      lv_price              := TO_CHAR( g_get_xmvc_tbl_tab(i).price );                                    -- �P��
--      lv_inventory_quantity := TO_CHAR( g_get_xmvc_tbl_tab(i).inventory_quantity );                       -- ���^����
--      lv_last_update_date   := TO_CHAR( g_get_xmvc_tbl_tab(i).last_update_date, 'YYYY/MM/DD HH24:MI:SS' );-- �X�V����
----
--      -- CSV�f�[�^���쐬
--      lv_csv_file := (
--        cv_encloser || g_get_xmvc_tbl_tab(i).cust_code || cv_encloser || cv_delimiter ||  -- �ڋq�R�[�h
--        cv_encloser || lv_column_no                    || cv_encloser || cv_delimiter ||  -- �R����No.
--        cv_encloser || g_get_xmvc_tbl_tab(i).item_code || cv_encloser || cv_delimiter ||  -- �i�ڃR�[�h
--                       lv_price                                       || cv_delimiter ||  -- �P��
--                       lv_inventory_quantity                          || cv_delimiter ||  -- ���^����
--        cv_encloser || g_get_xmvc_tbl_tab(i).hot_cold  || cv_encloser || cv_delimiter ||  -- H/C
--        cv_encloser || g_get_xmvc_tbl_tab(i).del_flag  || cv_encloser || cv_delimiter ||  -- �폜�t���O
--        cv_encloser || lv_last_update_date             || cv_encloser                     -- �X�V����
--      );
----
--      -- ===============================
--      -- CSV�f�[�^���o��
--      -- ===============================
--      UTL_FILE.PUT_LINE(
--          file   => g_file_handle
--        , buffer => lv_csv_file
--      );
----
--      -- ===============================
--      -- ���������J�E���g
--      -- ===============================
--      gn_normal_cnt := gn_normal_cnt + 1;
----
--    END LOOP create_file_loop;
--
    OPEN  get_xmvc_tbl_cur1;
    OPEN  get_xmvc_tbl_cur2;
    --
    <<cursor_loop>>
    FOR i IN  1 .. 2  LOOP
      <<create_file_loop>>
      LOOP
        IF (i = 1) THEN
          FETCH get_xmvc_tbl_cur1 INTO  get_xmvc_tbl_rec;
          EXIT WHEN get_xmvc_tbl_cur1%NOTFOUND;
        ELSE
          FETCH get_xmvc_tbl_cur2 INTO  get_xmvc_tbl_rec;
          EXIT WHEN get_xmvc_tbl_cur2%NOTFOUND;
        END IF;
        --
        lv_column_no          := TO_CHAR( get_xmvc_tbl_rec.column_no );                                -- �R����No.
        lv_price              := TO_CHAR( get_xmvc_tbl_rec.price );                                    -- �P��
        lv_inventory_quantity := TO_CHAR( get_xmvc_tbl_rec.inventory_quantity );                       -- ���^����
        lv_last_update_date   := TO_CHAR( get_xmvc_tbl_rec.last_update_date, 'YYYY/MM/DD HH24:MI:SS' );-- �X�V����
  --
        -- CSV�f�[�^���쐬
        lv_csv_file := (
          cv_encloser || get_xmvc_tbl_rec.cust_code || cv_encloser || cv_delimiter ||  -- �ڋq�R�[�h
          cv_encloser || lv_column_no               || cv_encloser || cv_delimiter ||  -- �R����No.
          cv_encloser || get_xmvc_tbl_rec.item_code || cv_encloser || cv_delimiter ||  -- �i�ڃR�[�h
                         lv_price                                  || cv_delimiter ||  -- �P��
                         lv_inventory_quantity                     || cv_delimiter ||  -- ���^����
          cv_encloser || get_xmvc_tbl_rec.hot_cold  || cv_encloser || cv_delimiter ||  -- H/C
          cv_encloser || get_xmvc_tbl_rec.del_flag  || cv_encloser || cv_delimiter ||  -- �폜�t���O
          cv_encloser || lv_last_update_date        || cv_encloser                     -- �X�V����
        );
  --
        -- ===============================
        -- CSV�f�[�^���o��
        -- ===============================
        UTL_FILE.PUT_LINE(
            file   => g_file_handle
          , buffer => lv_csv_file
        );
  --
        -- ===============================
        -- ���������J�E���g
        -- ===============================
        gn_target_cnt :=  gn_target_cnt + 1;
        gn_normal_cnt :=  gn_normal_cnt + 1;
      END LOOP create_file_loop;
    END LOOP cursor_loop;
    --
    CLOSE  get_xmvc_tbl_cur1;
    CLOSE  get_xmvc_tbl_cur2;
    --
    -- ===============================
    -- ���o0���`�F�b�N
    -- ===============================
    IF ( gn_target_cnt = 0 ) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcoi
                      , iv_name         => cv_no_data_msg
                    );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => gv_out_msg
      );
    END IF;
-- == 2009/09/14 V1.1 Modified START ===============================================================
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
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
-- == 2009/09/14 V1.1 Added START ===============================================================
      IF (get_xmvc_tbl_cur1%ISOPEN) THEN
        CLOSE get_xmvc_tbl_cur1;
      END IF;
      --
      IF (get_xmvc_tbl_cur2%ISOPEN) THEN
        CLOSE get_xmvc_tbl_cur1;
      END IF;
-- == 2009/09/14 V1.1 Added END   ===============================================================
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END create_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : upd_last_coop_date
   * Description      : �f�[�^�A�g���䃏�[�N�e�[�u���̍ŏI�A�g�����X�V(A-6)
   ***********************************************************************************/
  PROCEDURE upd_last_coop_date(
      ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_last_coop_date'; -- �v���O������
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
    -- ==============================================================
    -- �f�[�^�A�g���䃏�[�N�e�[�u���X�V����
    -- ==============================================================
    UPDATE   xxcoi_cooperation_control    xcc
    SET      xcc.last_cooperation_date  = gd_sysdate                 -- �ŏI�A�g����
           , xcc.last_update_date       = cd_last_update_date        -- �ŏI�X�V��
           , xcc.last_updated_by        = cn_last_updated_by         -- �ŏI�X�V��
           , xcc.last_update_login      = cn_last_update_login       -- �ŏI�X�V�҃��O�C��
           , xcc.request_id             = cn_request_id              -- �v��ID
           , xcc.program_application_id = cn_program_application_id  -- �A�v���P�[�V����ID
           , xcc.program_id             = cn_program_id              -- �v���O����ID
           , xcc.program_update_date    = cd_program_update_date     -- �v���O�����X�V����
    WHERE    xcc.program_id             = cn_program_id;             -- �X�V�����F�v���O����ID
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
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
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
  END upd_last_coop_date;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_open_mode    CONSTANT VARCHAR2(1) := 'w';  -- �I�[�v�����[�h�F��������
--
    -- *** ���[�J���ϐ� ***
    ln_file_length  NUMBER;                       -- �t�@�C���̒����̕ϐ�
    ln_block_size   NUMBER;                       -- �u���b�N�T�C�Y�̕ϐ�
    lb_fexists      BOOLEAN;                      -- �t�@�C�����݃`�F�b�N����
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
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- �������� (A-1)
    -- ===============================
    init(
        ov_errbuf  => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg  => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==============================================================
    -- �f�[�^�A�g���䃏�[�N�e�[�u���̍ŏI�A�g�����擾 (A-2)
    -- ==============================================================
    get_last_coop_date(
        ov_errbuf  => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg  => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- UTL�t�@�C���I�[�v�� (A-3)
    -- ===============================
    -- �t�@�C���̑��݃`�F�b�N
    UTL_FILE.FGETATTR(
        location    => gv_dire_name
      , filename    => gv_file_name
      , fexists     => lb_fexists
      , file_length => ln_file_length
      , block_size  => ln_block_size
    );
    IF( lb_fexists = TRUE ) THEN
      RAISE remain_file_expt;
    END IF;
--
    -- �t�@�C���̃I�[�v��
    g_file_handle := UTL_FILE.FOPEN(
                         location  => gv_dire_name
                       , filename  => gv_file_name
                       , open_mode => cv_open_mode
                     );
--
-- == 2009/09/14 V1.1 Deleted START ===============================================================
--    -- ===============================
--    -- VD�R�����}�X�^��񒊏o (A-4)
--    -- ===============================
--    get_mst_vd_column(
--        ov_errbuf  => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
--      , ov_retcode => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
--      , ov_errmsg  => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--    );
----
--    IF ( lv_retcode = cv_status_error ) THEN
--      RAISE global_process_expt;
--    END IF;
-- == 2009/09/14 V1.1 Deleted END   ===============================================================
--
    -- ===============================
    -- �x���_�݌Ƀ}�X�^CSV�쐬 (A-5)
    -- ===============================
    create_csv_file(
        ov_errbuf  => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg  => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �Ώی�����1���ȏ�̏ꍇ
    IF ( gn_target_cnt > 0 ) THEN
--
      -- ==============================================================
      -- �f�[�^�A�g���䃏�[�N�e�[�u���̍ŏI�A�g�����X�V (A-6)
      -- ==============================================================
      upd_last_coop_date(
          ov_errbuf  => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg  => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- ===============================
    -- UTL�t�@�C���N���[�Y (A-7)
    -- ===============================
    UTL_FILE.FCLOSE( file => g_file_handle );
--
  EXCEPTION
--
    -- *** �t�@�C�����݃`�F�b�N�G���[ ***
    WHEN remain_file_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcoi
                      , iv_name         => cv_file_remain_err_msg
                      , iv_token_name1  => cv_tkn_file_name
                      , iv_token_value1 => gv_file_name
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �t�@�C����OPEN���Ă���ꍇ
      IF ( UTL_FILE.IS_OPEN( file => g_file_handle ) ) THEN
        UTL_FILE.FCLOSE( file => g_file_handle );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �t�@�C����OPEN���Ă���ꍇ
      IF ( UTL_FILE.IS_OPEN( file => g_file_handle ) ) THEN
        UTL_FILE.FCLOSE( file => g_file_handle );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �t�@�C����OPEN���Ă���ꍇ
      IF ( UTL_FILE.IS_OPEN( file => g_file_handle ) ) THEN
        UTL_FILE.FCLOSE( file => g_file_handle );
      END IF;
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
      errbuf              OUT VARCHAR2       --   �G���[�E���b�Z�[�W  --# �Œ� #
    , retcode             OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
    , iv_night_exec_flag  IN  VARCHAR2)      --   ��Ԏ��s�t���O
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
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
      , ov_errbuf  => lv_errbuf
      , ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- �p�����[�^�̖�Ԏ��s�t���O���O���[�o���ϐ��Ɋi�[
    SELECT DECODE( iv_night_exec_flag
                 , cv_night_exec_flag_y
                 , cv_night_exec_flag_y
                 , cv_night_exec_flag_n )
    INTO   gv_night_exec_flag
    FROM   DUAL;
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
        ov_errbuf  => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg  => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      -- �G���[�̏ꍇ�A���������̏������ƃG���[�����̃Z�b�g
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      --�G���[�o��
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg       -- ���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf       -- �G���[���b�Z�[�W
      );
    END IF;
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxccp
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
--
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxccp
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
--
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxccp
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
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
                      iv_application  => cv_appl_short_name_xxccp
                    , iv_name         => lv_message_code
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
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
END XXCOI010A03C;
/
