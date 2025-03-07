create or replace PACKAGE BODY APPS.XXSCP001A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2024. All rights reserved.
 *
 * Package Name     : XXSCP001A03C(body)
 * Description      : �O���݌Ƀ��W���[���Y�v��FBDI�A�g
 *                    �O���̍݌ɐ��ʂ�CSV�o�͂���B
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2025/1/10     1.0  SCSK M.Sato      [E_�{�ғ�_20298]�V�K�쐬
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
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXSCP001A03C'; -- �p�b�P�[�W��
--
  --�v���t�@�C��
  cv_file_name_enter    CONSTANT VARCHAR2(30)  := 'XXSCP1_FILE_NAME_ON_HAND';         -- XXSCP:�O���݌Ƀt�@�C������
  cv_file_dir_enter     CONSTANT VARCHAR2(100) := 'XXSCP1_FILE_DIR_SUPPLY_PLANNING';  -- XXSCP:���Y�v��t�@�C���i�[�p�X
  cv_scaling_number     CONSTANT VARCHAR2(50)  := 'XXSCP1_SCALING_NUMBER';            -- XXSCP:�X�P�[���l
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date       DATE;             -- �Ɩ����t
  gv_file_name_enter    VARCHAR2(100) ;   -- XXSCP:�O���݌Ƀt�@�C������
  gv_file_dir_enter     VARCHAR2(500) ;   -- XXSCP:�O���݌Ƀt�@�C���i�[�p�X
  gn_scaling_number     NUMBER  ;         -- XXSCP:�X�P�[���l
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_open_mode_w      CONSTANT VARCHAR2(10) := 'w';     -- �t�@�C���I�[�v�����[�h�i�㏑���j
--
    -- *** ���[�J���ϐ� ***
--
    -- �ϐ��^�̐錾
    ln_transaction_count           NUMBER; 
    ln_transaction_value           NUMBER;
    ln_transaction_version         NUMBER;
    Id_transaction_close_day       DATE;
    lv_csv_text_h                  VARCHAR2(3000);
    lv_csv_text_l                  VARCHAR2(3000);
    lf_file_hand                   UTL_FILE.FILE_TYPE ;  -- �t�@�C���E�n���h���̐錾
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- CSV�o�͗p�J�[�\��
    CURSOR history_on_hand_cur
      IS
        SELECT  xhoh.item_name                   item_name                   -- �i�ڃR�[�h
               ,xhoh.organization_code           organization_code           -- ��\�g�D�R�[�h
               ,xhoh.sr_instance_code            sr_instance_code            -- �\�[�X�E�V�X�e���E�R�[�h
               ,xhoh.new_order_quantity          new_order_quantity          -- �݌ɐ���
               ,xhoh.subinventory_code           subinventory_code           -- �Œ�l�uS�v
               ,xhoh.deleted_flag                deleted_flag                -- �폜�t���O
               ,xhoh.end_value                   end_value                   -- �I�[�L��
        FROM   xxscp_his_on_hand xhoh
        WHERE  xhoh.version = ln_transaction_version
        ORDER BY xhoh.item_name
                ,xhoh.organization_code
        ;
--
    -- ���R�[�h�^�̐錾
    TYPE history_on_hand_rec IS RECORD (
     item_name                    VARCHAR2(250)    -- �i�ڃR�[�h
    ,organization_code            VARCHAR2(13)     -- ��\�g�D�R�[�h
    ,sr_instance_code             VARCHAR2(30)     -- �\�[�X�E�V�X�e���E�R�[�h
    ,new_order_quantity           NUMBER(10,3)     -- �݌ɐ���
    ,subinventory_code            VARCHAR2(10)     -- �Œ�l�uS�v
    ,deleted_flag                 VARCHAR2(3)      -- �폜�t���O
    ,end_value                    VARCHAR2(3)      -- �I�[�L��
    );
    history_on_hand_record history_on_hand_rec; 
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
    -- ������
    -- ===============================
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --==============================================================
    -- �Ɩ����t�擾
    --==============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := '�Ɩ����t�̎擾�Ɏ��s���܂����B';
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF
    ;
--
    --==============================================================
    -- �v���t�@�C���擾
    --==============================================================
    -- XXSCP:���Y�v��t�@�C���i�[�p�X�̎擾
    gv_file_dir_enter := FND_PROFILE.VALUE(cv_file_dir_enter);
    IF (gv_file_dir_enter IS NULL) THEN
      lv_errmsg := 'XXSCP:���Y�v��t�@�C���i�[�p�X�̎擾�Ɏ��s���܂����B';
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- XXSCP:�O���݌Ƀt�@�C�����̂̎擾
    gv_file_name_enter      := FND_PROFILE.VALUE(cv_file_name_enter);
    IF (gv_file_name_enter IS NULL) THEN
      lv_errmsg := 'XXSCP:�O���݌Ƀt�@�C�����̂̎擾�Ɏ��s���܂����B';
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- XXSCP:�X�P�[���l�̎擾
    gn_scaling_number       := TO_NUMBER(FND_PROFILE.VALUE(cv_scaling_number));
    IF (gn_scaling_number  IS NULL) THEN
      lv_errmsg := 'XXSCP:�X�P�[���l�̎擾�Ɏ��s���܂����B';
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ŐV�o�[�W�����̎擾
    SELECT xxscp_on_hand_ver_s1.NEXTVAL
    INTO   ln_transaction_version
    FROM   dual
    ;
--
    -- �q�ɂ̍ŏI�I���N������W�v�J�n�����擾
    SELECT ADD_MONTHS(TO_DATE(xxcmn_common_pkg.get_opminv_close_period || '01' ,'YYYYMMDD'),1)
    INTO   Id_transaction_close_day
    FROM   dual
    ;
--
    -- �O���̃g�����U�N�V�������擾���A�����e�[�u���ɓ���
    INSERT INTO xxscp_his_on_hand(
          his_on_hand_id                   -- �e�[�u��ID
         ,version                          -- �o�[�W����
         ,item_name                        -- �i�ڃR�[�h
         ,organization_code                -- ��\�g�D
         ,sr_instance_code                 -- �\�[�X�E�V�X�e���E�R�[�h(�Œ�l�uKI�v)
         ,new_order_quantity               -- �݌ɐ���
         ,subinventory_code                -- �Œ�l�uS�v
         ,deleted_flag                     -- �폜�t���O
         ,end_value                        -- �I�[�L��
         ,created_by                       -- CREATED_BY
         ,creation_date                    -- CREATION_DATE
         ,last_updated_by                  -- LAST_UPDATED_BY
         ,last_update_date                 -- LAST_UPDATE_DATE
         ,last_update_login                -- LAST_UPDATE_LOGIN
         ,request_id                       -- REQUEST_ID
         ,program_application_id           -- PROGRAM_APPLICATION_ID
         ,program_id                       -- PROGRAM_ID
         ,program_update_date              -- PROGRAM_UPDATE_DATE
     )
    SELECT
          xxscp_on_hand_id_s1.NEXTVAL      his_on_hand_id            -- �e�[�u��ID
         ,ln_transaction_version           version                   -- �o�[�W����
         ,toh.item_code                    item_code                 -- �i��
         ,toh.rep_org_code                 rep_org_code              -- ��\�g�D
         ,'KI'                             sr_instance_code          -- �\�[�X�E�V�X�e���E�R�[�h(�Œ�l�uKI�v)
         ,toh.on_hand_cs_num               on_hand_cs_num            -- �O���݌ɃP�[�X��
         ,'S'                              subinventory_code         -- �Œ�l�uS�v
         ,''                               deleted_flag              -- �폜�t���O
         ,'END'                            end_value                 -- �I�[�L��
         ,cn_created_by                    created_by                -- CREATED_BY
         ,cd_creation_date                 creation_date             -- CREATION_DATE
         ,cn_last_updated_by               last_updated_by           -- LAST_UPDATED_BY
         ,cd_last_update_date              last_update_date          -- LAST_UPDATE_DATE
         ,cn_last_update_login             last_update_login         -- LAST_UPDATE_LOGIN
         ,cn_request_id                    request_id                -- REQUEST_ID
         ,cn_program_application_id        program_application_id    -- PROGRAM_APPLICATION_ID
         ,cn_program_id                    program_id                -- PROGRAM_ID
         ,cd_program_update_date           program_update_date       -- PROGRAM_UPDATE_DATE
    FROM
          (  --�g�D�R�[�h�A�i�ڃR�[�h�P�ʂŏW�v
             SELECT
                      tran.rep_org_code                                    rep_org_code        -- �g�D�R�[�h
                     ,tran.item_code                                       item_code           -- �i�ڃR�[�h
                     ,SUM( tran.month_qty)/gn_scaling_number               on_hand_cs_num      -- �O���݌ɃP�[�X��(�X�P�[���l�Ō����𒲐�)
               FROM(
                       --======================================================================
                       -- �I�������݌Ƀe�[�u�����猎��݌ɐ��Ƃ��čŌ�ɒ��܂������̌����݌ɐ����擾
                       --   �ˁy����݌ɐ��{�O���܂ł̓��o�ɐ��̐ςݏグ�z�ɂ���đO���̍݌ɐ������߂�
                       --======================================================================
                        SELECT
                                xwm.rep_org_code              rep_org_code        -- �g�D�R�[�h
                               ,xsim.item_code                item_code           -- �i�ڃR�[�h
                               ,(NVL( xsim.monthly_stock, 0 ) + NVL( xsim.cargo_stock, 0 ))/iimb.attribute11
                                                              month_qty           -- �����݌ɃP�[�X��
                        FROM
                                xxinv_stc_inventory_month_stck    xsim            -- �I�������݌ɃA�h�I��
                               ,ic_item_mst_b                     iimb            -- OPM�i�ڃ}�X�^
                               ,xxcmn_item_locations_v            xilv            -- ���P�[�V�����A�C�e��View
                               ,xxscp_warehouse_mst               xwm             -- �i�ڑq�Ƀ}�X�^
                        WHERE
                              ( xsim.cargo_stock <> 0  OR  xsim.monthly_stock <> 0 )
                           AND  xsim.invent_ym                = TO_CHAR(Id_transaction_close_day-1,'YYYYMM')
                           AND  xsim.item_id                  = iimb.item_id
                           AND  xsim.whse_code                = xilv.whse_code
                           AND  xilv.segment1                 = xwm.whse_code
                           AND  xsim.item_code                = xwm.item_code
                           AND  xwm.rep_org_code             <> 'DUMMY'
                           AND  xilv.description       NOT LIKE '��u%' 
                       --<< �I�������݌Ƀe�[�u���猎��݌ɐ��Ƃ��đO���̌����݌ɐ����擾 END >>--
                      UNION ALL
                       --======================================================================
                       -- �e�g�����U�N�V�������猎�ԓ��ɐ����擾
                       --  �P�D�d����ԕi
                       --  �Q�D�����������
                       --  �R�D�ړ����Ɏ���
                          -- �R-�P�D�ړ����ɗ\��i03:�������j
                          -- �R-�Q�D�ړ����ɗ\��i04:�o�ɕ񍐍ρj
                          -- �R-�R�D�ړ����Ɏ��сi05:���ɕ񍐍ρj
                          -- �R-�S�D�ړ����Ɏ��сi06:���o�ɕ񍐍ρj
                       --  �S�D�q�֕ԕi���Ɏ���
                          -- �S-�P�D�q�֕ԕi���Ɏ���
                          -- �S-�Q�D�q�֕ԕi���Ɏ��сi����j
                       --  �T�D���̑�����
                       -- �e�g�����U�N�V�������猎�ԏo�ɐ����擾
                       --  �P�D�o�׎���
                          -- �P-�P�D�o�׎��сi04:���ьv��ρj
                          -- �P-�Q�D�o�׎��сi03:���ߍρj-- ���і����͂̏o�א��ʂ��W�v
                       --  �Q�D�L���x������
                          -- �Q-�P�D�L���x�����сi�ԕi�̏ꍇ���Ɉ����j
                          -- �Q-�Q�D�L���x������
                       --  �R�D���{��p���o�׎���
                       --  �S�D�ړ��o�Ɏ���
                          -- �S-�P�D�ړ��o�ɗ\��i03�F�������j
                          -- �S-�Q�D�ړ��o�Ɏ��сi04�F�o�ɕ񍐍ρj
                          -- �S-�R�D�ړ��o�Ɏ��сi05�F���ɕ񍐍ρj
                       --======================================================================
                        ----------------------------------------------------------------------
                        -- �P�D�d����ԕi  �c�}�C�i�X�l�ŏo��
                        ----------------------------------------------------------------------
                        SELECT
                               /*+
                                  LEADING(xrp)
                                  USE_NL(xrp itc)
                                */
                                xwm.rep_org_code               rep_org_code        -- �g�D�R�[�h
                               ,iimb.item_no                   item_code           -- �i�ڃR�[�h
                               ,itc.trans_qty/iimb.attribute11 month_qty           -- �P�[�X����
                         FROM
                                xxcmn_rcv_pay_mst              xrp                 -- �󕥋敪�A�h�I���}�X�^
                               ,ic_tran_cmp                    itc                 -- OPM�����݌Ƀg�����U�N�V����
                               ,xxcmn_item_locations_v         xilv                -- ���P�[�V�����A�C�e��View
                               ,ic_item_mst_b                  iimb                -- OPM�i�ڃ}�X�^
                               ,xxscp_warehouse_mst            xwm                 -- �i�ڑq�Ƀ}�X�^
                         WHERE
                                xrp.doc_type                  = 'ADJI'
                           AND  xrp.reason_code               = 'X201'             -- �d���ԕi�o��
                           AND  xrp.rcv_pay_div               = '1'                -- ���
                           AND  xrp.use_div_invent            = 'Y'
                           AND  itc.trans_qty                <> 0
                           AND  itc.doc_type                  = xrp.doc_type
                           AND  itc.reason_code               = xrp.reason_code
                           AND  itc.trans_date               >= Id_transaction_close_day
                                                                                   -- �Ō�ɍ݌ɂ����܂������̗�����������
                           AND  itc.trans_date                < gd_process_date    -- �O���܂�
                           AND  itc.item_id                   = iimb.item_id
                           AND  iimb.item_no                  = xwm.item_code
                           AND  itc.location                  = xwm.whse_code
                           AND  xwm.rep_org_code             <> 'DUMMY'
                           AND  xwm.whse_code                 = xilv.segment1
                           AND  xilv.description       NOT LIKE '��u%' 
                        --[ �P�D�d����ԕi END ]--
                      UNION ALL
                        ----------------------------------------------------------------------
                        -- �Q�D�����������
                        ----------------------------------------------------------------------
                        SELECT
                                xwm.rep_org_code              rep_org_code        -- �g�D�R�[�h
                               ,xrt.item_code                 item_code           -- �i��ID
                               ,xrt.quantity/iimb.attribute11 month_qty           -- �����݌Ƀo����
                         FROM
                                po_headers_all                pha                 -- �����w�b�_
                               ,po_lines_all                  pla                 -- ��������
                               ,xxpo_rcv_and_rtn_txns         xrt                 -- ����ԕi����(�A�h�I��)
                               ,ic_item_mst_b                 iimb                -- OPM�i�ڃ}�X�^
                               ,xxscp_warehouse_mst           xwm                 -- �i�ڑq�Ƀ}�X�^
                               ,xxcmn_item_locations_v        xilv                -- ���P�[�V�����A�C�e��View
                         WHERE
                                pha.attribute1                IN ( '25'           -- �������
                                                                 , '30'           -- ���ʊm���
                                                                 , '35' )         -- ���z�m���
                           AND  pla.attribute13               = 'Y'               -- ������
                           AND  pla.cancel_flag              <> 'Y'               -- �L�����Z���ȊO
                           AND  pha.po_header_id              = pla.po_header_id
                           AND  xrt.source_document_number    = pha.segment1
                           AND  xrt.source_document_line_num  = pla.line_num
                           AND  xrt.txns_type                 = '1'               -- ���
                           AND  xrt.quantity                 <> 0
                           AND  xrt.txns_date                >= Id_transaction_close_day
                                                                                  -- �Ō�ɍ݌ɂ����܂������̗�����������
                           AND  xrt.txns_date                 < gd_process_date   -- �O���܂�
                           AND  xrt.item_id                   = iimb.item_id
                           AND  xrt.item_code                 = xwm.item_code
                           AND  pha.attribute5                = xwm.whse_code
                           AND  xwm.rep_org_code             <> 'DUMMY'
                           AND  xwm.whse_code                 = xilv.segment1
                           AND  xilv.description       NOT LIKE '��u%' 
                        --[ �Q�D����������� END ]--
                      UNION ALL
                        ----------------------------------------------------------------------
                        -- �R-�P�D�ړ����ɗ\��i03:�������j
                        ----------------------------------------------------------------------
                        SELECT
                        /*+
                                LEADING(xmrih xmril xwm1)
                                INDEX(xmril XXINV_MRIL_N02)
                        */
                                xwm2.rep_org_code             rep_org_code        -- �g�D�R�[�h�iTO�j
                               ,xmril.item_code               item_code           -- �i�ڃR�[�h
                               ,xmril.instruct_qty /iimb.attribute11
                                                              month_qty           -- �P�[�X����
                          FROM
                                xxinv_mov_req_instr_headers   xmrih               -- �ړ��˗�/�w���w�b�_(�A�h�I��)
                               ,xxinv_mov_req_instr_lines     xmril               -- �ړ��˗�/�w������(�A�h�I��)
                               ,ic_item_mst_b                 iimb                -- OPM�i�ڃ}�X�^
                               ,xxscp_warehouse_mst           xwm1                -- �i�ڑq�Ƀ}�X�^(FROM)
                               ,xxscp_warehouse_mst           xwm2                -- �i�ڑq�Ƀ}�X�^(TO)
                               ,xxcmn_item_locations_v        xilv1               -- ���P�[�V�����A�C�e��View(�o�Ɍ�)
                               ,xxcmn_item_locations_v        xilv2               -- ���P�[�V�����A�C�e��View(���ɐ�)
                         WHERE
                                xmrih.status                    = '03'             -- 03�F������
                           AND  xmrih.notif_status              = '40'             -- 40�m��ʒm��
                           AND  xmrih.schedule_arrival_date    >= Id_transaction_close_day
                                                                                   -- �Ō�ɍ݌ɂ����܂������̗�����������
                           AND  xmrih.schedule_arrival_date     < gd_process_date  -- �O���܂�
                           AND  xmril.delete_flg                = 'N'             -- OFF
                           AND  xmrih.mov_hdr_id                = xmril.mov_hdr_id
                           AND  xmril.item_code                 = iimb.item_no
                           AND  xmril.item_code                 = xwm1.item_code
                           AND  xmrih.shipped_locat_code        = xwm1.whse_code
                           -- DUMMY�q�ɂɎd���ꂽ���i���݌ɂƂ��Ĉړ�����ꍇ�����邽�߁A�R�����g�A�E�g
                           --AND  xwm1.rep_org_code              <> 'DUMMY'
                           AND  xmril.item_code                 = xwm2.item_code
                           AND  xmrih.ship_to_locat_code        = xwm2.whse_code
                           AND  xwm2.rep_org_code              <> 'DUMMY'
                           AND  xwm1.rep_org_code              <> xwm2.rep_org_code            -- ����g�D�Ԃ̈ړ��͑ΏۊO
                           AND  xmrih.shipped_locat_id          = xilv1.inventory_location_id
                           AND  xmrih.ship_to_locat_id          = xilv2.inventory_location_id
                           AND  xilv1.description        NOT LIKE '��u%' 
                           AND  xilv2.description        NOT LIKE '��u%' 
                        --[ �R-�P�D�ړ����Ɏ��� END ]--
                      UNION ALL
                        ----------------------------------------------------------------------
                        -- �R-�Q�D�ړ����ɗ\��i04:�o�ɕ񍐍ρj
                        ----------------------------------------------------------------------
                        SELECT
                        /*+
                                LEADING(xmrih xmril xwm1)
                                INDEX(xmril XXINV_MRIL_N02)
                        */
                                xwm2.rep_org_code             rep_org_code        -- �g�D�R�[�h�iTO�j
                               ,xmril.item_code               item_code           -- �i�ڃR�[�h
                               ,xmril.shipped_quantity /iimb.attribute11
                                                              month_qty           -- �P�[�X����
                          FROM
                                xxinv_mov_req_instr_headers   xmrih               -- �ړ��˗�/�w���w�b�_(�A�h�I��)
                               ,xxinv_mov_req_instr_lines     xmril               -- �ړ��˗�/�w������(�A�h�I��)
                               ,ic_item_mst_b                 iimb                -- OPM�i�ڃ}�X�^
                               ,xxscp_warehouse_mst           xwm1                -- �i�ڑq�Ƀ}�X�^(FROM)
                               ,xxscp_warehouse_mst           xwm2                -- �i�ڑq�Ƀ}�X�^(TO)
                               ,xxcmn_item_locations_v        xilv1               -- ���P�[�V�����A�C�e��View(�o�Ɍ�)
                               ,xxcmn_item_locations_v        xilv2               -- ���P�[�V�����A�C�e��View(���ɐ�)
                         WHERE
                                xmrih.status                    = '04'            -- 04:�o�ɕ񍐍�
                           AND  xmrih.schedule_arrival_date    >= Id_transaction_close_day
                                                                                  -- �Ō�ɍ݌ɂ����܂������̗�����������
                           AND  xmrih.schedule_arrival_date     < gd_process_date -- �O���܂�
                           AND  xmril.delete_flg                = 'N'             -- OFF
                           AND  xmrih.mov_hdr_id                = xmril.mov_hdr_id
                           AND  xmril.item_code                 = iimb.item_no
                           AND  xmril.item_code                 = xwm1.item_code
                           AND  xmrih.shipped_locat_code        = xwm1.whse_code
                           -- DUMMY�q�ɂɎd���ꂽ���i���݌ɂƂ��Ĉړ�����ꍇ�����邽�߁A�R�����g�A�E�g
                           --AND  xwm1.rep_org_code              <> 'DUMMY'
                           AND  xmril.item_code                 = xwm2.item_code
                           AND  xmrih.ship_to_locat_code        = xwm2.whse_code
                           AND  xwm2.rep_org_code              <> 'DUMMY'
                           AND  xwm1.rep_org_code              <> xwm2.rep_org_code            -- ����g�D�Ԃ̈ړ��͑ΏۊO
                           AND  xmrih.shipped_locat_id          = xilv1.inventory_location_id
                           AND  xmrih.ship_to_locat_id          = xilv2.inventory_location_id
                           AND  xilv1.description        NOT LIKE '��u%' 
                           AND  xilv2.description        NOT LIKE '��u%' 
                        --[ �R-�Q�D�ړ����Ɏ��� END ]--
                      UNION ALL
                        ----------------------------------------------------------------------
                        -- �R-�R�D�ړ����Ɏ��сi05:���ɕ񍐍ρj
                        ----------------------------------------------------------------------
                        SELECT
                        /*+
                                LEADING(xmrih xmril xwm1)
                                INDEX(xmril XXINV_MRIL_N02)
                        */
                                xwm2.rep_org_code             rep_org_code        -- �g�D�R�[�h�iTO�j
                               ,xmril.item_code               item_code           -- �i�ڃR�[�h
                               ,xmril.ship_to_quantity/iimb.attribute11
                                                              month_qty           -- �P�[�X����
                          FROM
                                xxinv_mov_req_instr_headers   xmrih               -- �ړ��˗�/�w���w�b�_(�A�h�I��)
                               ,xxinv_mov_req_instr_lines     xmril               -- �ړ��˗�/�w������(�A�h�I��)
                               ,ic_item_mst_b                 iimb                -- OPM�i�ڃ}�X�^
                               ,xxscp_warehouse_mst           xwm1                -- �i�ڑq�Ƀ}�X�^(FROM)
                               ,xxscp_warehouse_mst           xwm2                -- �i�ڑq�Ƀ}�X�^(TO)
                               ,xxcmn_item_locations_v        xilv1               -- ���P�[�V�����A�C�e��View(�o�Ɍ�)
                               ,xxcmn_item_locations_v        xilv2               -- ���P�[�V�����A�C�e��View(���ɐ�)
                         WHERE
                                xmrih.status                    = '05'            -- 05:���ɕ񍐗L
                           AND  xmrih.actual_arrival_date      >= Id_transaction_close_day
                                                                                  -- �Ō�ɍ݌ɂ����܂������̗�����������
                           AND  xmrih.actual_arrival_date       < gd_process_date -- �����O���܂�
                           AND  xmril.delete_flg                = 'N'             -- OFF
                           AND  xmrih.mov_hdr_id                = xmril.mov_hdr_id
                           AND  xmril.item_code                 = iimb.item_no
                           AND  xmril.item_code                 = xwm1.item_code
                           AND  xmrih.shipped_locat_code        = xwm1.whse_code
                           -- DUMMY�q�ɂɎd���ꂽ���i���݌ɂƂ��Ĉړ�����ꍇ�����邽�߁A�R�����g�A�E�g
                           --AND  xwm1.rep_org_code              <> 'DUMMY'
                           AND  xmril.item_code                 = xwm2.item_code
                           AND  xmrih.ship_to_locat_code        = xwm2.whse_code
                           AND  xwm2.rep_org_code              <> 'DUMMY'
                           AND  xwm1.rep_org_code              <> xwm2.rep_org_code            -- ����g�D�Ԃ̈ړ��͑ΏۊO
                           AND  xmrih.shipped_locat_id          = xilv1.inventory_location_id
                           AND  xmrih.ship_to_locat_id          = xilv2.inventory_location_id
                           AND  xilv1.description        NOT LIKE '��u%' 
                           AND  xilv2.description        NOT LIKE '��u%' 
                        --[ �R-�R�D�ړ����Ɏ��� END ]--
                      UNION ALL
                       ----------------------------------------------------------------------
                        -- �R-�S�D�ړ����Ɏ��сi06:���o�ɕ񍐍ρj
                        ----------------------------------------------------------------------
                       SELECT
                        /*+
                                LEADING(xmrih xmril xwm1)
                                INDEX(xmril XXINV_MRIL_N02)
                        */
                                xwm2.rep_org_code             rep_org_code        -- �g�D�R�[�h�iTO�j
                               ,xmril.item_code               item_code             -- �i�ڃR�[�h
                               ,xmril.ship_to_quantity/iimb.attribute11
                                                              month_qty           -- �P�[�X����
                          FROM
                                xxinv_mov_req_instr_headers   xmrih               -- �ړ��˗�/�w���w�b�_(�A�h�I��)
                               ,xxinv_mov_req_instr_lines     xmril               -- �ړ��˗�/�w������(�A�h�I��)
                               ,ic_item_mst_b                 iimb                -- OPM�i�ڃ}�X�^
                               ,xxscp_warehouse_mst           xwm1                -- �i�ڑq�Ƀ}�X�^(FROM)
                               ,xxscp_warehouse_mst           xwm2                -- �i�ڑq�Ƀ}�X�^(TO)
                               ,xxcmn_item_locations_v        xilv1               -- ���P�[�V�����A�C�e��View(�o�Ɍ�)
                               ,xxcmn_item_locations_v        xilv2               -- ���P�[�V�����A�C�e��View(���ɐ�)
                         WHERE
                                xmrih.status                    = '06'            -- 06:���o�ɕ�
                           AND  xmrih.actual_arrival_date      >= Id_transaction_close_day
                                                                                  -- �Ō�ɍ݌ɂ����܂������̗�����������
                           AND  xmrih.actual_arrival_date       < gd_process_date -- �����O���܂�
                           AND  xmril.delete_flg                = 'N'             -- OFF
                           AND  xmrih.mov_hdr_id                = xmril.mov_hdr_id
                           AND  xmril.item_code                 = iimb.item_no
                           AND  xmril.item_code                 = xwm1.item_code
                           AND  xmrih.shipped_locat_code        = xwm1.whse_code
                           -- DUMMY�q�ɂɎd���ꂽ���i���݌ɂƂ��Ĉړ�����ꍇ�����邽�߁A�R�����g�A�E�g
                           --AND  xwm1.rep_org_code              <> 'DUMMY'
                           AND  xmril.item_code                 = xwm2.item_code
                           AND  xmrih.ship_to_locat_code        = xwm2.whse_code
                           AND  xwm2.rep_org_code              <> 'DUMMY'
                           AND  xwm1.rep_org_code              <> xwm2.rep_org_code            -- ����g�D�Ԃ̈ړ��͑ΏۊO
                           AND  xmrih.shipped_locat_id          = xilv1.inventory_location_id
                           AND  xmrih.ship_to_locat_id          = xilv2.inventory_location_id
                           AND  xilv1.description        NOT LIKE '��u%' 
                           AND  xilv2.description        NOT LIKE '��u%' 
                        --[ �R-�S�D�ړ����Ɏ��� END ]--
                      UNION ALL
                        ----------------------------------------------------------------------
                        -- �S-�P�D�q�֕ԕi���Ɏ���
                        ----------------------------------------------------------------------
                        SELECT
                                xwm.rep_org_code              rep_org_code         -- �g�D�R�[�h
                               ,xola.shipping_item_code       item_code            -- �i�ڃR�[�h
                               ,xola.shipped_quantity/iimb.attribute11
                                                              month_qty            -- �P�[�X����
                          FROM
                                xxwsh_order_headers_all       xoha                 -- �󒍃w�b�_
                               ,xxwsh_order_lines_all         xola                 -- �󒍖���
                               ,oe_transaction_types_all      ota                  -- �󒍃^�C�v
                               ,xxscp_warehouse_mst           xwm                  -- �i�ڑq�Ƀ}�X�^
                               ,ic_item_mst_b                 iimb                 -- OPM�i�ڃ}�X�^
                         WHERE
                                xoha.req_status                       = '04'       -- ���ьv���
                           AND  NVL( xoha.latest_external_flag, 'N' ) = 'Y'        -- ON
                           AND  xoha.arrival_date                    >= Id_transaction_close_day
                           AND  xoha.arrival_date                     < gd_process_date
                           AND  ota.attribute1                        = '3'        -- �q�֕ԕi
                           AND  xoha.order_type_id                    = ota.transaction_type_id
                           AND  ota.order_category_code               = 'ORDER'
                           AND  NVL( xola.delete_flag, 'N' )         <> 'Y'        -- �������׈ȊO
                           AND  xoha.order_header_id                  = xola.order_header_id
                           AND  xola.shipping_item_code               = xwm.item_code
                           AND  xoha.deliver_from                     = xwm.whse_code
                           AND  xwm.rep_org_code                     <> 'DUMMY'
                           AND  xola.shipping_item_code               = iimb.item_no
                        --[ �S�D�q�֕ԕi���Ɏ��� END ]--
                      UNION ALL
                       ----------------------------------------------------------------------
                        -- �S-�Q�D�q�֕ԕi���Ɏ��сi����j
                        ----------------------------------------------------------------------
                         SELECT
                                xwm.rep_org_code              rep_org_code               -- �g�D�R�[�h
                               ,xola.shipping_item_code       item_code                  -- �i�ڃR�[�h
                               ,xola.shipped_quantity/iimb.attribute11 * - 1             -- ����Ȃ�o�Ɉ���
                                                              month_qty                  -- �P�[�X����
                          FROM
                                xxwsh_order_headers_all       xoha                       -- �󒍃w�b�_
                               ,xxwsh_order_lines_all         xola                       -- �󒍖���
                               ,oe_transaction_types_all      ota                        -- �󒍃^�C�v
                               ,xxscp_warehouse_mst           xwm                        -- �i�ڑq�Ƀ}�X�^
                               ,ic_item_mst_b                 iimb                       -- OPM�i�ڃ}�X�^
                         WHERE
                                xoha.req_status                       = '04'             -- ���ьv���
                           AND  NVL( xoha.latest_external_flag, 'N' ) = 'Y'              -- ON
                           AND  xoha.arrival_date                    >= Id_transaction_close_day
                                                                                         -- �Ō�ɍ݌ɂ����܂������̗�����������
                           AND  xoha.arrival_date                     < gd_process_date  -- �O���܂�
                           AND  ota.attribute1                        = '3'              -- �q�֕ԕi
                           AND  xoha.order_type_id                    = ota.transaction_type_id
                           AND  ota.order_category_code               = 'RETURN'
                           AND  NVL( xola.delete_flag, 'N' )         <> 'Y'              -- �������׈ȊO
                           AND  xoha.order_header_id                  = xola.order_header_id
                           AND  xola.shipping_item_code               = xwm.item_code
                           AND  xoha.deliver_from                     = xwm.whse_code
                           AND  xwm.rep_org_code                     <> 'DUMMY'
                           AND  xola.shipping_item_code               = iimb.item_no
                        --[ �S�D�q�֕ԕi���Ɏ��� END ]--
                      UNION ALL
                        ----------------------------------------------------------------------
                        -- �T�D���̑�����
                        ----------------------------------------------------------------------
                        SELECT
                               /*+
                                  LEADING(xrp)
                                  USE_NL(xrp itc)
                                */
                                xwm.rep_org_code               rep_org_code        -- �g�D�R�[�h
                               ,iimb.item_no                   item_code           -- �i�ڃR�[�h
                               ,itc.trans_qty/iimb.attribute11 month_qty           -- �P�[�X����
                         FROM
                                xxcmn_rcv_pay_mst              xrp                 -- �󕥋敪�A�h�I���}�X�^
                               ,ic_tran_cmp                    itc                 -- OPM�����݌Ƀg�����U�N�V����
                               ,xxcmn_item_locations_v         xilv                -- ���P�[�V�����A�C�e��View
                               ,ic_item_mst_b                  iimb                -- OPM�i�ڃ}�X�^
                               ,xxscp_warehouse_mst            xwm                 -- �i�ڑq�Ƀ}�X�^
                         WHERE
                                XRP.doc_type                  = 'ADJI'
                           AND  XRP.reason_code              <> 'X977'             -- �����݌�
                           AND  XRP.reason_code              <> 'X988'             -- �l������
                           AND  XRP.reason_code              <> 'X123'             -- �ړ����ђ����i�o�Ɂj
                           AND  XRP.reason_code              <> 'X201'             -- �d����ԕi
                           AND  XRP.rcv_pay_div               = '1'                -- ���
                           AND  XRP.use_div_invent            = 'Y'
                           AND  itc.trans_qty                <> 0
                           AND  itc.doc_type                  = xrp.doc_type
                           AND  itc.reason_code               = xrp.reason_code
                           AND  itc.trans_date               >= Id_transaction_close_day
                                                                                   -- �Ō�ɍ݌ɂ����܂������̗�����������
                           AND  itc.trans_date                < gd_process_date    -- �����O���܂�
                           AND  itc.item_id                   = iimb.item_id
                           AND  iimb.item_no                  = xwm.item_code
                           AND  itc.location                  = xwm.whse_code
                           AND  xwm.rep_org_code             <> 'DUMMY'
                           AND  xwm.whse_code                 = xilv.segment1
                           AND  xilv.description       NOT LIKE '��u%' 
                        --[ �T�D���̑����� END ]--
                       --<< �e�g�����U�N�V�������猎�ԓ��ɐ����擾 END >>--
                      UNION ALL
                       --======================================================================
                       -- �e�g�����U�N�V�������猎�ԏo�ɐ����擾
                       --  �P�D�o�׎���
                       --  �Q�D�L���x������
                       --  �R�D���{��p���o�׎���
                       --  �S�D�ړ��o�Ɏ���
                       --  �T�D���̑��o��
                       --======================================================================
                        ----------------------------------------------------------------------
                        -- �P-�P�D�o�׎��сi04:���ьv��ρj
                        ----------------------------------------------------------------------
                        SELECT
                                xwm.rep_org_code              rep_org_code                -- �g�D�R�[�h
                               ,xola.shipping_item_code       item_code                   -- �i�ڃR�[�h
                               ,xola.shipped_quantity/iimb.attribute11 * -1
                                                              month_qty                   -- �P�[�X����
                          FROM
                                xxwsh_order_headers_all       xoha                        -- �󒍃w�b�_
                               ,xxwsh_order_lines_all         xola                        -- �󒍖���
                               ,oe_transaction_types_all      ota                         -- �󒍃^�C�v
                               ,xxscp_warehouse_mst           xwm                         -- �i�ڑq�Ƀ}�X�^
                               ,ic_item_mst_b                 iimb                        -- OPM�i�ڃ}�X�^
                         WHERE
                                xoha.req_status                       = '04'              -- ���ьv���
                           AND  NVL( xoha.latest_external_flag, 'N' ) = 'Y'               -- ON
                           AND  xoha.arrival_date                    >= Id_transaction_close_day
                                                                                          -- �Ō�ɍ݌ɂ����܂������̗�����������
                           AND  xoha.arrival_date                     < gd_process_date   -- �O���܂�
                           AND  ota.attribute1                        = '1'               -- �o�׈˗�
                           AND  ota.attribute4                        = '1'               -- �ʏ�o��
                           AND  ota.order_category_code               = 'ORDER'
                           AND  xoha.order_type_id                    = ota.transaction_type_id
                           AND  NVL( xola.delete_flag, 'N' )         <> 'Y'               -- �������׈ȊO
                           AND  xoha.order_header_id                  = xola.order_header_id
                           AND  xola.shipping_item_code               = xwm.item_code
                           AND  xoha.deliver_from                     = xwm.whse_code
                           AND  xwm.rep_org_code                     <> 'DUMMY'
                           AND  xola.shipping_item_code               = iimb.item_no
                        --[ �P�D�o�ץ�q�Ԏ��� END ]--
                      UNION ALL
                        ----------------------------------------------------------------------
                        -- �P-�Q�D�o�׎��сi03:���ߍρj-- ���і����͂̏o�א��ʂ��W�v
                        ----------------------------------------------------------------------
                        SELECT
                                xwm.rep_org_code              rep_org_code                -- �g�D�R�[�h
                               ,xola.shipping_item_code       item_code                   -- �i�ڃR�[�h
                               ,xola.quantity/iimb.attribute11 * -1
                                                              month_qty                   -- �P�[�X����
                          FROM
                                xxwsh_order_headers_all       xoha                        -- �󒍃w�b�_
                               ,xxwsh_order_lines_all         xola                        -- �󒍖���
                               ,oe_transaction_types_all      ota                         -- �󒍃^�C�v
                               ,xxscp_warehouse_mst           xwm                         -- �i�ڑq�Ƀ}�X�^
                               ,ic_item_mst_b                 iimb                        -- OPM�i�ڃ}�X�^
                         WHERE
                                xoha.req_status                       = '03'              -- ���ьv���
                           AND  xoha.notif_status                     = '40'              -- �m��ʒm��
                           AND  NVL( xoha.latest_external_flag, 'N' ) = 'Y'               -- ON
                           AND  xoha.schedule_arrival_date           >= Id_transaction_close_day
                                                                                          -- �Ō�ɍ݌ɂ����܂������̗�����������
                           AND  xoha.schedule_arrival_date            < gd_process_date   -- �O���܂�
                           AND  ota.attribute1                        = '1'               -- �o�׈˗�
                           AND  ota.attribute4                        = '1'               -- �ʏ�o��
                           AND  ota.order_category_code               = 'ORDER'
                           AND  xoha.order_type_id                    = ota.transaction_type_id
                           AND  NVL( xola.delete_flag, 'N' )         <> 'Y'               -- �������׈ȊO
                           AND  xoha.order_header_id                  = xola.order_header_id
                           AND  xola.shipping_item_code               = xwm.item_code
                           AND  xoha.deliver_from                     = xwm.whse_code
                           AND  xwm.rep_org_code                     <> 'DUMMY'
                           AND  xola.shipping_item_code               = iimb.item_no
                        --[ �P�D�o�ץ�q�Ԏ��� END ]--
                      UNION ALL
                        ----------------------------------------------------------------------
                        -- �Q-�P�D�L���x�����сi�ԕi�̏ꍇ���Ɉ����j
                        ----------------------------------------------------------------------
                        SELECT
                                xwm.rep_org_code              rep_org_code               -- �g�D�R�[�h
                               ,xola.shipping_item_code       item_code                  -- �i�ڃR�[�h
                               ,xola.shipped_quantity/iimb.attribute11                   -- �ԕi�Ȃ���Ɉ���
                                                              month_qty                  -- �P�[�X����
                          FROM
                                xxwsh_order_headers_all       xoha                       -- �󒍃w�b�_
                               ,xxwsh_order_lines_all         xola                       -- �󒍖���
                               ,oe_transaction_types_all      ota                        -- �󒍃^�C�v
                               ,xxscp_warehouse_mst           xwm                        -- �i�ڑq�Ƀ}�X�^
                               ,ic_item_mst_b                 iimb                       -- OPM�i�ڃ}�X�^
                         WHERE
                                xoha.req_status                       = '08'             -- ���ьv���
                           AND  NVL( xoha.latest_external_flag, 'N' ) = 'Y'              -- ON
                           AND  xoha.arrival_date                    >= Id_transaction_close_day
                                                                                         -- �Ō�ɍ݌ɂ����܂������̗�����������
                           AND  xoha.arrival_date                     < gd_process_date  -- �O���܂�
                           AND  ota.attribute1                        = '2'              -- �x��
                           AND  xoha.order_type_id                    = ota.transaction_type_id
                           AND  ota.order_category_code               = 'RETURN'
                           AND  NVL( xola.delete_flag, 'N' )         <> 'Y'              -- �������׈ȊO
                           AND  xoha.order_header_id                  = xola.order_header_id
                           AND  xola.shipping_item_code               = xwm.item_code
                           AND  xoha.deliver_from                     = xwm.whse_code
                           AND  xwm.rep_org_code                     <> 'DUMMY'
                           AND  xola.shipping_item_code               = iimb.item_no
                        --[ �Q-�P�D�L���x������ END ]--
                      UNION ALL
                        ----------------------------------------------------------------------
                        -- �Q-�Q�D�L���x������
                        ----------------------------------------------------------------------
                        SELECT
                                xwm.rep_org_code              rep_org_code               -- �g�D�R�[�h
                               ,xola.shipping_item_code       item_code                  -- �i�ڃR�[�h
                               ,xola.shipped_quantity/iimb.attribute11 * -1
                                                              month_qty                  -- �P�[�X����
                          FROM
                                xxwsh_order_headers_all       xoha                       -- �󒍃w�b�_
                               ,xxwsh_order_lines_all         xola                       -- �󒍖���
                               ,oe_transaction_types_all      ota                        -- �󒍃^�C�v
                               ,xxscp_warehouse_mst           xwm                        -- �i�ڑq�Ƀ}�X�^
                               ,ic_item_mst_b                 iimb                       -- OPM�i�ڃ}�X�^
                         WHERE
                                xoha.req_status                       = '08'             -- ���ьv���
                           AND  NVL( xoha.latest_external_flag, 'N' ) = 'Y'              -- ON
                           AND  xoha.arrival_date                    >= Id_transaction_close_day
                                                                                         -- �Ō�ɍ݌ɂ����܂������̗�����������
                           AND  xoha.arrival_date                     < gd_process_date  -- �O���܂�
                           AND  ota.attribute1                        = '2'              -- �x��
                           AND  xoha.order_type_id                    = ota.transaction_type_id
                           AND  ota.order_category_code               = 'ORDER'
                           AND  NVL( xola.delete_flag, 'N' )         <> 'Y'              -- �������׈ȊO
                           AND  xoha.order_header_id                  = xola.order_header_id
                           AND  xola.shipping_item_code               = xwm.item_code
                           AND  xoha.deliver_from                     = xwm.whse_code
                           AND  xwm.rep_org_code                     <> 'DUMMY'
                           AND  xola.shipping_item_code               = iimb.item_no
                        --[ �Q-�Q�D�L���x������ END ]--
                      UNION ALL
                        ----------------------------------------------------------------------
                        -- �R�D���{��p���o�׎���
                        ----------------------------------------------------------------------
                        SELECT
                                xwm.rep_org_code              rep_org_code                -- �g�D�R�[�h
                               ,xola.shipping_item_code       item_code                   -- �i�ڃR�[�h
                               ,xola.shipped_quantity/iimb.attribute11 * -1
                                                              month_qty                   -- �P�[�X����
                          FROM
                                xxwsh_order_headers_all       xoha                        -- �󒍃w�b�_
                               ,xxwsh_order_lines_all         xola                        -- �󒍖���
                               ,oe_transaction_types_all      ota                         -- �󒍃^�C�v
                               ,xxscp_warehouse_mst           xwm                         -- �i�ڑq�Ƀ}�X�^
                               ,ic_item_mst_b                 iimb                        -- OPM�i�ڃ}�X�^
                         WHERE
                                xoha.req_status                       = '04'              -- ���ьv���
                           AND  NVL( xoha.latest_external_flag, 'N' ) = 'Y'               -- ON
                           AND  ota.attribute1                        = '1'               -- �o�׈˗�
                           AND  ota.attribute4                        = '2'               -- ���{��p���o��
                           AND  ota.order_category_code               = 'ORDER'
                           AND  xoha.order_type_id                    = ota.transaction_type_id
                           AND  NVL( xola.delete_flag, 'N' )         <> 'Y'               -- �������׈ȊO
                           AND  xoha.order_header_id                  = xola.order_header_id
                           AND  xoha.arrival_date                    >= Id_transaction_close_day
                                                                                          -- �Ō�ɍ݌ɂ����܂������̗�����������
                           AND  xoha.arrival_date                     < gd_process_date   -- �O���܂�
                           AND  xola.shipping_item_code               = xwm.item_code
                           AND  xoha.deliver_from                     = xwm.whse_code
                           AND  xwm.rep_org_code                     <> 'DUMMY'
                           AND  xola.shipping_item_code               = iimb.item_no
                        --[ �R�D�o�ץ�q�Ԏ��� END ]--
                      UNION ALL
                        ----------------------------------------------------------------------
                        -- �S-�P�D�ړ��o�ɗ\��i03�F�������j
                        ----------------------------------------------------------------------
                        SELECT
                        /*+
                                LEADING(xmrih xmril xwm1)
                                INDEX(xmril XXINV_MRIL_N02)
                        */
                                xwm1.rep_org_code             rep_org_code         -- �g�D�R�[�h
                               ,xmril.item_code               item_code            -- �i�ڃR�[�h
                               ,xmril.instruct_qty /iimb.attribute11 * - 1
                                                              month_qty            -- �P�[�X����
                          FROM
                                xxinv_mov_req_instr_headers   xmrih                -- �ړ��˗�/�w���w�b�_(�A�h�I��)
                               ,xxinv_mov_req_instr_lines     xmril                -- �ړ��˗�/�w������(�A�h�I��)
                               ,ic_item_mst_b                 iimb                 -- OPM�i�ڃ}�X�^
                               ,xxcmn_item_locations_v        xilv1                -- ���P�[�V�����A�C�e��View(�o�Ɍ�)
                               ,xxcmn_item_locations_v        xilv2                -- ���P�[�V�����A�C�e��View(���ɐ�)
                               ,xxscp_warehouse_mst           xwm1                 -- �i�ڑq�Ƀ}�X�^(FROM)
                               ,xxscp_warehouse_mst           xwm2                 -- �i�ڑq�Ƀ}�X�^(TO)
                         WHERE
                                xmrih.status                    = '03'             -- 03�F������
                           AND  xmrih.notif_status              = '40'             -- 40�m��ʒm��
                           AND  xmrih.schedule_arrival_date    >= Id_transaction_close_day
                                                                                   -- �Ō�ɍ݌ɂ����܂������̗�����������
                           AND  xmrih.schedule_arrival_date     < gd_process_date  -- �����O���܂�
                           AND  xmril.delete_flg                = 'N'              -- OFF
                           AND  xmrih.mov_hdr_id                = xmril.mov_hdr_id
                           AND  xmril.item_code                 = iimb.item_no
                           AND  xmril.item_code                 = xwm1.item_code
                           AND  xmrih.shipped_locat_code        = xwm1.whse_code
                           AND  xwm1.rep_org_code              <> 'DUMMY'
                           AND  xmril.item_code                 = xwm2.item_code
                           AND  xmrih.ship_to_locat_code        = xwm2.whse_code
                           -- DUMMY�q�ɂɈړ�����ꍇ������̂ŃR�����g�A�E�g
                           -- AND  xwm2.rep_org_code              <> 'DUMMY'
                           AND  xwm1.rep_org_code <> xwm2.rep_org_code             -- ����g�D�Ԃ̈ړ��͑ΏۊO
                           AND  xmrih.shipped_locat_id          = xilv1.inventory_location_id
                           AND  xmrih.ship_to_locat_id          = xilv2.inventory_location_id
                           AND  xilv1.description        NOT LIKE '��u%' 
                           AND  xilv2.description        NOT LIKE '��u%' 
                        --[ �S-�P�D�ړ��o�׎��� END ]--
                      UNION ALL
                        ----------------------------------------------------------------------
                        -- �S-�Q�D�ړ��o�Ɏ��сi04�F�o�ɕ񍐍ρj
                        ----------------------------------------------------------------------
                        SELECT
                        /*+
                                LEADING(xmrih xmril xwm1)
                                INDEX(xmril XXINV_MRIL_N02)
                        */
                                xwm1.rep_org_code             rep_org_code         -- �g�D�R�[�h
                               ,xmril.item_code               item_code            -- �i�ڃR�[�h
                               ,xmril.shipped_quantity /iimb.attribute11 * - 1
                                                              month_qty            -- �P�[�X����
                          FROM
                                xxinv_mov_req_instr_headers   xmrih                -- �ړ��˗�/�w���w�b�_(�A�h�I��)
                               ,xxinv_mov_req_instr_lines     xmril                -- �ړ��˗�/�w������(�A�h�I��)
                               ,ic_item_mst_b                 iimb                 -- OPM�i�ڃ}�X�^
                               ,xxcmn_item_locations_v        xilv1                -- ���P�[�V�����A�C�e��View(�o�Ɍ�)
                               ,xxcmn_item_locations_v        xilv2                -- ���P�[�V�����A�C�e��View(���ɐ�)
                               ,xxscp_warehouse_mst           xwm1                 -- �i�ڑq�Ƀ}�X�^(FROM)
                               ,xxscp_warehouse_mst           xwm2                 -- �i�ڑq�Ƀ}�X�^(TO)
                         WHERE
                                xmrih.status                    = '04'             -- 04�F�o�ɕ񍐍�
                           AND  xmrih.schedule_arrival_date    >= Id_transaction_close_day
                                                                                   -- �Ō�ɍ݌ɂ����܂������̗�����������
                           AND  xmrih.schedule_arrival_date     < gd_process_date  -- �����O���܂�
                           AND  xmril.delete_flg                = 'N'              -- OFF
                           AND  xmrih.mov_hdr_id                = xmril.mov_hdr_id
                           AND  xmril.item_code                 = iimb.item_no
                           AND  xmril.item_code                 = xwm1.item_code
                           AND  xmrih.shipped_locat_code        = xwm1.whse_code
                           AND  xwm1.rep_org_code              <> 'DUMMY'
                           AND  xmril.item_code                 = xwm2.item_code
                           AND  xmrih.ship_to_locat_code        = xwm2.whse_code
                           -- DUMMY�q�ɂɈړ�����ꍇ������̂ŃR�����g�A�E�g
                           -- AND  xwm2.rep_org_code              <> 'DUMMY'
                           AND  xwm1.rep_org_code <> xwm2.rep_org_code             -- ����g�D�Ԃ̈ړ��͑ΏۊO
                           AND  xmrih.shipped_locat_id          = xilv1.inventory_location_id
                           AND  xmrih.ship_to_locat_id          = xilv2.inventory_location_id
                           AND  xilv1.description        NOT LIKE '��u%' 
                           AND  xilv2.description        NOT LIKE '��u%' 
                        --[ �S-�Q�D�ړ��o�׎��� END ]--
                      UNION ALL
                        ----------------------------------------------------------------------
                        -- �S-�R�D�ړ��o�Ɏ��сi05�F���ɕ񍐍ρj
                        ----------------------------------------------------------------------
                        SELECT
                        /*+
                                LEADING(xmrih xmril xwm1)
                                INDEX(xmril XXINV_MRIL_N02)
                        */
                                xwm1.rep_org_code             rep_org_code         -- �g�D�R�[�h
                               ,xmril.item_code               item_code            -- �i�ڃR�[�h
                               ,xmril.shipped_quantity /iimb.attribute11 * - 1
                                                              month_qty            -- �P�[�X����
                          FROM
                                xxinv_mov_req_instr_headers   xmrih                -- �ړ��˗�/�w���w�b�_(�A�h�I��)
                               ,xxinv_mov_req_instr_lines     xmril                -- �ړ��˗�/�w������(�A�h�I��)
                               ,ic_item_mst_b                 iimb                 -- OPM�i�ڃ}�X�^
                               ,xxcmn_item_locations_v        xilv1                -- ���P�[�V�����A�C�e��View(�o�Ɍ�)
                               ,xxcmn_item_locations_v        xilv2                -- ���P�[�V�����A�C�e��View(���ɐ�)
                               ,xxscp_warehouse_mst           xwm1                 -- �i�ڑq�Ƀ}�X�^(FROM)
                               ,xxscp_warehouse_mst           xwm2                 -- �i�ڑq�Ƀ}�X�^(TO)
                         WHERE
                                xmrih.status                    = '05'             -- 05�F���ɕ񍐍�
                           AND  xmrih.actual_arrival_date      >= Id_transaction_close_day
                                                                                   -- �Ō�ɍ݌ɂ����܂������̗�����������
                           AND  xmrih.actual_arrival_date       < gd_process_date  -- �����O���܂�
                           AND  xmril.delete_flg                = 'N'              -- OFF
                           AND  xmrih.mov_hdr_id                = xmril.mov_hdr_id
                           AND  xmril.item_code                 = iimb.item_no
                           AND  xmril.item_code                 = xwm1.item_code
                           AND  xmrih.shipped_locat_code        = xwm1.whse_code
                           AND  xwm1.rep_org_code              <> 'DUMMY'
                           AND  xmril.item_code                 = xwm2.item_code
                           AND  xmrih.ship_to_locat_code        = xwm2.whse_code
                           -- DUMMY�q�ɂɈړ�����ꍇ������̂ŃR�����g�A�E�g
                           -- AND  xwm2.rep_org_code           <> 'DUMMY'
                           AND  xwm1.rep_org_code              <> xwm2.rep_org_code             -- ����g�D�Ԃ̈ړ��͑ΏۊO
                           -- xxcmn_item_locations_v�Ƃ̌���
                           AND  xmrih.shipped_locat_id          = xilv1.inventory_location_id
                           AND  xmrih.ship_to_locat_id          = xilv2.inventory_location_id
                           AND  xilv1.description        NOT LIKE '��u%' 
                           AND  xilv2.description        NOT LIKE '��u%' 
                        --[ �S-�R�D�ړ��o�׎��� END ]--
                      UNION ALL
                        ----------------------------------------------------------------------
                        -- �S-�S�D�ړ��o�Ɏ��сi06�F���o�ɕ񍐍ρj
                        ----------------------------------------------------------------------
                        SELECT
                        /*+
                                LEADING(xmrih xmril xwm1)
                                INDEX(xmril XXINV_MRIL_N02)
                        */
                                xwm1.rep_org_code             rep_org_code         -- �g�D�R�[�h
                               ,xmril.item_code               item_code            -- �i�ڃR�[�h
                               ,xmril.shipped_quantity /iimb.attribute11 * - 1
                                                              month_qty            -- �P�[�X����
                          FROM
                                xxinv_mov_req_instr_headers   xmrih                -- �ړ��˗�/�w���w�b�_(�A�h�I��)
                               ,xxinv_mov_req_instr_lines     xmril                -- �ړ��˗�/�w������(�A�h�I��)
                               ,ic_item_mst_b                 iimb                 -- OPM�i�ڃ}�X�^
                               ,xxcmn_item_locations_v        xilv1                -- ���P�[�V�����A�C�e��View(�o�Ɍ�)
                               ,xxcmn_item_locations_v        xilv2                -- ���P�[�V�����A�C�e��View(���ɐ�)
                               ,xxscp_warehouse_mst           xwm1                 -- �i�ڑq�Ƀ}�X�^(FROM)
                               ,xxscp_warehouse_mst           xwm2                 -- �i�ڑq�Ƀ}�X�^(TO)
                         WHERE
                                xmrih.status                    = '06'             -- 06�F���o�ɕ񍐍�
                           AND  xmrih.actual_arrival_date      >= Id_transaction_close_day
                                                                                   -- �Ō�ɍ݌ɂ����܂������̗�����������
                           AND  xmrih.actual_arrival_date       < gd_process_date  -- �����O���܂�
                           AND  xmril.delete_flg                = 'N'              -- OFF
                           AND  xmrih.mov_hdr_id                = xmril.mov_hdr_id
                           AND  xmril.item_code                 = iimb.item_no
                           AND  xmril.item_code                 = xwm1.item_code
                           AND  xmrih.shipped_locat_code        = xwm1.whse_code
                           AND  xwm1.rep_org_code              <> 'DUMMY'
                           AND  xmril.item_code                 = xwm2.item_code
                           AND  xmrih.ship_to_locat_code        = xwm2.whse_code
                           -- DUMMY�q�ɂɈړ�����ꍇ������̂ŃR�����g�A�E�g
                           -- AND  xwm2.rep_org_code           <> 'DUMMY'
                           AND  xwm1.rep_org_code              <> xwm2.rep_org_code             -- ����g�D�Ԃ̈ړ��͑ΏۊO
                           AND  xmrih.shipped_locat_id          = xilv1.inventory_location_id
                           AND  xmrih.ship_to_locat_id          = xilv2.inventory_location_id
                           AND  xilv1.description        NOT LIKE '��u%' 
                           AND  xilv2.description        NOT LIKE '��u%' 
                        --[ �S-�S�D�ړ��o�׎��� END ]--
                      UNION ALL
                        ----------------------------------------------------------------------
                        -- �T�D���̑��o��
                        ----------------------------------------------------------------------
                        SELECT
                               /*+
                                  LEADING(xrp)
                                  USE_NL(xrp itc)
                                */
                                xwm.rep_org_code               rep_org_code        -- �g�D�R�[�h
                               ,iimb.item_no                   item_code           -- �i�ڃR�[�h
                               ,itc.trans_qty/iimb.attribute11 month_qty           -- �P�[�X����
                        FROM
                                xxcmn_rcv_pay_mst             xrp                  -- �󕥋敪�A�h�I���}�X�^
                               ,ic_tran_cmp                   itc                  -- OPM�����݌Ƀg�����U�N�V����
                               ,xxcmn_item_locations_v        xilv                 -- �m�F�@�ۊǏꏊ���̂�sysdate�Ŏ擾���Ă��邪���Ȃ���
                               ,ic_item_mst_b                 iimb                 -- OPM�i�ڃ}�X�^
                               ,xxscp_warehouse_mst           xwm                  -- �i�ڑq�Ƀ}�X�^
                         WHERE
                                XRP.doc_type                  = 'ADJI'
                           AND  XRP.reason_code              <> 'X977'             --�����݌�
                           AND  XRP.reason_code              <> 'X123'             --�ړ����ђ����i�o�Ɂj
                           AND  XRP.rcv_pay_div               = '-1'               --���o
                           AND  XRP.use_div_invent            = 'Y'
                           AND  itc.trans_qty                <> 0
                           AND  itc.doc_type                  = xrp.doc_type
                           AND  itc.reason_code               = xrp.reason_code
                           AND  itc.trans_date               >= Id_transaction_close_day
                                                                                   -- �Ō�ɍ݌ɂ����܂������̗�����������
                           AND  itc.trans_date                < gd_process_date    -- �����O���܂�
                           AND  itc.item_id                   = iimb.item_id
                           AND  iimb.item_no                  = xwm.item_code
                           AND  itc.location                  = xwm.whse_code
                           AND  xwm.rep_org_code             <> 'DUMMY'
                           AND  xwm.whse_code                 = xilv.segment1
                           AND  xilv.description       NOT LIKE '��u%' 
                        --[ �T�D���̑����� END ]--
                       --<< �e�g�����U�N�V�������猎�ԏo�ɐ����擾 END >>--
                     )  tran
             GROUP BY  tran.rep_org_code
                      ,tran.item_code
          )toh
    ;
--
    -- �R�~�b�g����
    COMMIT;
--
    -- ====================================================
    -- �t�s�k�t�@�C���I�[�v��
    -- ====================================================
    lf_file_hand := UTL_FILE.FOPEN(gv_file_dir_enter,
                                   gv_file_name_enter,
                                   cv_open_mode_w,
                                   32767
                                  );
--
    -- ===============================
    -- CSV�w�b�_������
    -- ===============================
--
    -- �w�b�_�[���ݒ�
    lv_csv_text_h := 'ITEM_NAME,ORGANIZATION_CODE,SR_INSTANCE_CODE,NEW_ORDER_QUANTITY,SUBINVENTORY_CODE,LOT_NUMBER,EXPIRATION_DATE,DELETED_FLAG,GLOBAL_ATTRIBUTE_NUMBER11,GLOBAL_ATTRIBUTE_NUMBER12,GLOBAL_ATTRIBUTE_NUMBER13,GLOBAL_ATTRIBUTE_NUMBER14,GLOBAL_ATTRIBUTE_NUMBER15,GLOBAL_ATTRIBUTE_NUMBER16,GLOBAL_ATTRIBUTE_NUMBER17,GLOBAL_ATTRIBUTE_NUMBER18,GLOBAL_ATTRIBUTE_NUMBER19,GLOBAL_ATTRIBUTE_NUMBER20,GLOBAL_ATTRIBUTE_NUMBER21,GLOBAL_ATTRIBUTE_NUMBER22,GLOBAL_ATTRIBUTE_NUMBER23,GLOBAL_ATTRIBUTE_NUMBER24,GLOBAL_ATTRIBUTE_NUMBER25,HOLD_DATE,GLOBAL_ATTRIBUTE_CHAR21,GLOBAL_ATTRIBUTE_CHAR22,GLOBAL_ATTRIBUTE_CHAR23,MATURITY_DATE,END'
;
--
    -- �w�b�_�[���ݒ胍�O�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_csv_text_h
    );
--
    -- ====================================================
    -- �w�b�_�[��CSV�o��
    -- ====================================================
    UTL_FILE.PUT_LINE( lf_file_hand, lv_csv_text_h ) ;
--
    -- ===============================
    -- CSV���ו�����
    -- ===============================
--
    -- �J�[�\���̃I�[�v��
    OPEN history_on_hand_cur;
--
    -- �f�[�^���o��
    LOOP
      FETCH history_on_hand_cur INTO history_on_hand_record;
      EXIT WHEN history_on_hand_cur%NOTFOUND;
--
      --�����Z�b�g
      gn_target_cnt := gn_target_cnt + 1;
--
      -- ���ו��ݒ�
      lv_csv_text_l :=    history_on_hand_record.item_name                                            || ','
                       || history_on_hand_record.organization_code                                    || ','
                       || history_on_hand_record.sr_instance_code                                     || ','
                       || RTRIM(TO_CHAR(history_on_hand_record.new_order_quantity, 'FM9999990.999'), '.')  || ','
                       || history_on_hand_record.subinventory_code                                    || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || history_on_hand_record.deleted_flag                                         || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || history_on_hand_record.end_value
                       ;
--
      -- ���ו��ݒ胍�O�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_csv_text_l)
      ;
--
      -- ====================================================
      -- ���ו�CSV�o��
      -- ====================================================
      UTL_FILE.PUT_LINE( lf_file_hand, lv_csv_text_l ) ;
--
    END LOOP;
    CLOSE history_on_hand_cur;
--
    -- ====================================================
    -- �t�s�k�t�@�C���N���[�Y
    -- ====================================================
    UTL_FILE.FCLOSE( lf_file_hand );
--
    -- �����������Ώی���
    gn_normal_cnt  := gn_target_cnt;
--
    -- �Ώی���=0�ł���Όx��
    IF (gn_target_cnt = 0) THEN
      ov_retcode     := cv_status_warn;
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
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF UTL_FILE.IS_OPEN  ( lf_file_hand ) THEN
         UTL_FILE.FCLOSE   ( lf_file_hand );
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
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
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
       iv_which   => 'LOG'
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
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      gn_error_cnt := 1;
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
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (lv_retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
    --�X�e�[�^�X�Z�b�g
    ov_retcode := lv_retcode;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      lv_retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      lv_retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXSCP001A03C;
/